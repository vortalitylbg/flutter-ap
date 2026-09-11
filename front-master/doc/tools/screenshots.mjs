// Captures d'écran automatisées de ResaChev via le protocole DevTools de Chrome.
// Aucune dépendance npm : Node >= 22 (WebSocket natif) + google-chrome-stable.
// Usage : node doc/tools/screenshots.mjs http://127.0.0.1:8765 doc/images
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [BASE = 'http://127.0.0.1:8765', OUT = 'doc/images'] = process.argv.slice(2);
const CHROME = process.env.CHROME ?? 'google-chrome-stable';
const PORT = 9333;
mkdirSync(OUT, { recursive: true });

const profile = join(tmpdir(), `resachev-shots-${process.pid}`);
const chrome = spawn(CHROME, [
  '--headless=new', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
  `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--window-size=1280,900', 'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let target;
for (let i = 0; i < 50 && !target; i++) {
  try { target = (await (await fetch(`http://127.0.0.1:${PORT}/json`)).json()).find((t) => t.type === 'page'); }
  catch { await sleep(200); }
}
if (!target) { chrome.kill(); throw new Error('Chrome injoignable'); }

const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const events = [];
ws.onmessage = ({ data }) => {
  const m = JSON.parse(data);
  if (m.id) { pending.get(m.id)?.(m); pending.delete(m.id); } else events.push(m);
};
const send = (method, params = {}) => new Promise((r) => { pending.set(++id, r); ws.send(JSON.stringify({ id, method, params })); });
const evaluate = async (expression) => (await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true })).result?.result?.value;

await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 2, mobile: false });

async function goto(path) {
  await send('Page.navigate', { url: BASE + path });
  await sleep(700);
  await evaluate('document.fonts.ready.then(() => true)');
}
async function shot(name, { height = null } = {}) {
  let clip;
  {
    // Hauteur du contenu réel (hors min-height:100vh), ou hauteur imposée pour les pages courtes
    const h = height ?? await evaluate('Math.min(document.documentElement.scrollHeight, 4000)');
    await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: h, deviceScaleFactor: 2, mobile: false });
    await sleep(150);
    clip = { x: 0, y: 0, width: 1280, height: h, scale: 1 };
  }
  const { result } = await send('Page.captureScreenshot', { format: 'png', clip, captureBeyondViewport: true });
  writeFileSync(join(OUT, `${name}.png`), Buffer.from(result.data, 'base64'));
  await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 2, mobile: false });
  console.log(`✔ ${name}.png`);
}

// --- Parcours public
await goto('/');                       await shot('01-accueil');
await goto('/connexion');              await shot('02-connexion', { height: 640 });
// Erreur d'identifiants
await evaluate(`(() => { const f = document.querySelector('form'); f.email.value = 'inconnu@example.com'; f.motpasse.value = 'x'; f.submit(); })()`);
await sleep(900);                      await shot('03-connexion-erreur', { height: 640 });
await goto('/mot-de-passe-oublie');    await shot('04-mot-de-passe-oublie', { height: 640 });
// --- Connexion avec 2FA (MAIL_MAILER=log : le code est lu dans le fichier de log)
await goto('/connexion');
await evaluate(`(() => { const f = document.querySelector('form'); f.email.value = 'jean.dupont@example.com'; f.motpasse.value = 'demo1234'; f.submit(); })()`);
await sleep(1500);                     await shot('05-verification-2fa', { height: 640 });
const log = readFileSync(process.env.LOG_FILE ?? 'storage/logs/laravel.log', 'utf8');
const codes = [...log.matchAll(/letter-spacing: 0\.3em;">(\d{6})</g)].map((m) => m[1]);
const code = codes.at(-1);
if (!code) { chrome.kill(); throw new Error('Code 2FA introuvable dans le log'); }
// Rendu de l'email 2FA (extrait du log) pour la documentation
const emailHtml = log.slice(log.lastIndexOf('<!DOCTYPE html>', log.lastIndexOf(code)), log.indexOf('</html>', log.lastIndexOf(code)) + 7);
await send('Page.navigate', { url: 'data:text/html;charset=utf-8,' + encodeURIComponent(emailHtml) });
await sleep(500);
{
  const { result } = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 600, height: 260, scale: 1 } });
  writeFileSync(join(OUT, '06-email-code-2fa.png'), Buffer.from(result.data, 'base64'));
  console.log('✔ 06-email-code-2fa.png');
}
await goto('/connexion/verification');
await evaluate(`(() => { const f = document.querySelector('form'); f.code.value = '${code}'; f.submit(); })()`);
await sleep(1500);                     await shot('07-tableau-de-bord');
// Navigation semaine suivante dans la grille Vue.js
await evaluate(`(() => { const b = [...document.querySelectorAll('button')].find(b => b.textContent.trim() === '›'); b && b.click(); })()`);
await sleep(900);                      await shot('08-tableau-de-bord-semaine-suivante');
await goto('/espace/profil');          await shot('09-profil', { height: 640 });
await goto('/espace/qrcode');          await shot('10-qrcode', { height: 900 });
// Vue mobile du tableau de bord
await goto('/api-doc');                await shot('11-api-doc');
await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
await goto('/espace/tableau-de-bord');
{
  const { result } = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 390, height: 844, scale: 1 } });
  writeFileSync(join(OUT, '12-tableau-de-bord-mobile.png'), Buffer.from(result.data, 'base64'));
  console.log('✔ 12-tableau-de-bord-mobile.png');
}

ws.close(); chrome.kill();
