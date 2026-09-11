<?php
// Markdown → HTML (league/commonmark, fourni par Laravel) → PDF (Chrome headless).
// Deux passes : la première mesure la page de chaque titre (pdftotext), la seconde
// injecte les numéros dans la table des matières.
// Usage : php doc/tools/md2pdf.php doc/sfd-std.md doc/sfd-std.pdf
//
// Ce dépôt est un projet Flutter : il n'a pas de dossier vendor/ PHP. On réutilise
// donc l'autoload de Composer du dépôt web (league/commonmark y est fourni par
// Laravel), attendu à côté de ce dépôt. Chemin surchargeable par la variable
// d'environnement AUTOLOAD. Le script ne fonctionne donc que sur un poste où
// les deux dépôts sont clonés côte à côte et 'composer install' a été lancé.
$autoloads = array_filter([
    getenv('AUTOLOAD') ?: null,
    __DIR__.'/../../vendor/autoload.php',           // vendor local, si un jour présent
    __DIR__.'/../../../front/vendor/autoload.php',  // dépôt web voisin
]);
$autoload = null;
foreach ($autoloads as $candidat) {
    if (is_file($candidat)) { $autoload = $candidat; break; }
}
if ($autoload === null) {
    fwrite(STDERR, "Autoload Composer introuvable (league/commonmark).\n"
        ."Cloner le dépôt web à côté de celui-ci et y lancer 'composer install',\n"
        ."ou pointer la variable AUTOLOAD sur un vendor/autoload.php.\n");
    exit(1);
}
require $autoload;

use League\CommonMark\Environment\Environment;
use League\CommonMark\Extension\CommonMark\CommonMarkCoreExtension;
use League\CommonMark\Extension\GithubFlavoredMarkdownExtension;
use League\CommonMark\Extension\HeadingPermalink\HeadingPermalinkExtension;
use League\CommonMark\MarkdownConverter;

[$_, $src, $dst] = $argv + [null, 'doc/sfd-std.md', 'doc/sfd-std.pdf'];
$dst = realpath(dirname($dst)).'/'.basename($dst);
$chrome = getenv('CHROME') ?: 'google-chrome-stable';

$env = new Environment(['heading_permalink' => ['symbol' => '', 'insert' => 'before', 'apply_id_to_heading' => true]]);
$env->addExtension(new CommonMarkCoreExtension());
$env->addExtension(new GithubFlavoredMarkdownExtension());
$env->addExtension(new HeadingPermalinkExtension());
$html = (new MarkdownConverter($env))->convert(file_get_contents($src))->getContent();
$html = preg_replace('#<a [^>]*class="heading-permalink"[^>]*></a>#', '', $html);

// Images (PNG/SVG) embarquées en base64 → HTML autonome
$dir = dirname(realpath($src));
$html = preg_replace_callback('/<img src="([^"]+)"/', function ($m) use ($dir) {
    $p = $dir.'/'.$m[1];
    if (!is_file($p)) return $m[0];
    $mime = str_ends_with($p, '.svg') ? 'image/svg+xml' : 'image/png';
    return '<img src="data:'.$mime.';base64,'.base64_encode(file_get_contents($p)).'"';
}, $html);

$html = preg_replace('#<p>\\\\pagebreak</p>#', '<div class="pagebreak"></div>', $html);

// Table des matières : titres h2/h3 (hors page de garde)
preg_match_all('#<h([23]) id="([^"]+)">(.*?)</h\1>#s', $html, $mm, PREG_SET_ORDER);
$headings = array_map(fn ($m) => ['level' => (int) $m[1], 'id' => $m[2], 'text' => trim(strip_tags($m[3]))], $mm);

function renderToc(array $headings, array $pages): string
{
    $out = '<nav class="toc"><h2 class="toc-titre">Table des matières</h2>';
    foreach ($headings as $h) {
        $n = $pages[$h['id']] ?? '';
        $out .= sprintf('<a class="toc-l%d" href="#%s"><span class="t">%s</span><span class="d"></span><span class="n">%s</span></a>',
            $h['level'], $h['id'], htmlspecialchars($h['text']), $n);
    }
    return $out.'</nav><div class="pagebreak"></div>';
}

function buildPage(string $html, string $toc): string
{
    $css = file_get_contents(__DIR__.'/style.css');
    $html = str_replace('<p>[[TOC]]</p>', $toc, $html);
    return "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\"><title>ResaChev - Application mobile - SFD / STD</title><style>$css</style></head><body>$html</body></html>";
}

function toPdf(string $chrome, string $page, string $pdf): void
{
    $tmp = tempnam(sys_get_temp_dir(), 'sfd').'.html';
    file_put_contents($tmp, $page);
    passthru(sprintf('%s --headless=new --no-sandbox --disable-gpu --no-pdf-header-footer --print-to-pdf=%s %s 2>/dev/null',
        $chrome, escapeshellarg($pdf), escapeshellarg('file://'.$tmp)), $code);
    unlink($tmp);
    if ($code !== 0) { fwrite(STDERR, "Chrome a échoué (code $code)\n"); exit($code); }
}

$norm = fn (string $s) => preg_replace('/\s+/', '', html_entity_decode($s)); // comparaison sans espaces (pdftotext en insère autour du code)

// Passe 1 : sans numéros
toPdf($chrome, buildPage($html, renderToc($headings, [])), $dst);

// Localisation des titres page par page (on ignore les pages de la table des matières)
$nb = (int) preg_replace('/.*Pages:\s+(\d+).*/s', '$1', shell_exec('pdfinfo '.escapeshellarg($dst)));
$pages = [];
$restants = $headings;
for ($p = 1; $p <= $nb && $restants; $p++) {
    $txt = $norm(shell_exec(sprintf('pdftotext -layout -f %d -l %d %s -', $p, $p, escapeshellarg($dst))));
    if (str_contains($txt, 'Tabledesmatières')) continue; // pages de la table des matières
    foreach ($restants as $i => $h) {
        if (str_contains($txt, $norm($h['text']))) { $pages[$h['id']] = $p; unset($restants[$i]); }
    }
}

// Passe 2 : avec numéros
$page = buildPage($html, renderToc($headings, $pages));
if (getenv('DEBUG_HTML')) file_put_contents(preg_replace('/\.pdf$/', '.html', $dst), $page);
toPdf($chrome, $page, $dst);
