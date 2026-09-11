@extends('layouts.app')

@section('titre', 'Tableau de bord – ResaChev')

@section('contenu')
    <div class="mb-4">
        <h1 class="h3 mb-0">Bienvenue, {{ $utilisateur->prenom }} {{ $utilisateur->nom }}&nbsp;!</h1>
    </div>

    {{-- Prochaine réservation --}}
    @if ($prochaineReservation)
        <div class="card shadow-sm mb-4">
            <div class="card-header fw-semibold">Prochaine réservation</div>
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col">
                        <div class="fs-4 fw-bold">{{ $prochaineReservation->prestation->libelleprestation }}</div>
                        <div class="text-muted mt-1">
                            {{ $prochaineReservation->datedebut->translatedFormat('l d F Y') }}
                            &mdash;
                            {{ $prochaineReservation->heuredebut->format('H:i') }}
                        </div>
                    </div>
                    <div class="col-auto">
                        @if ($prochaineReservation->validationpresence)
                            <span class="badge bg-success fs-6 px-3 py-2">Présence validée</span>
                        @else
                            <a href="{{ route('espace.qrcode') }}" class="badge bg-warning text-dark fs-6 px-3 py-2 text-decoration-none">
                                Afficher mon QR Code
                            </a>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    @else
        <div class="alert alert-secondary mb-4">Aucune réservation à venir.</div>
    @endif

    {{--
        Grille de créneaux — gérée par Vue.js
        ======================================
        Tout ce qui est à l'intérieur de #app-creneaux est contrôlé par Vue.js.
        Les directives Vue (v-if, v-for, @click, :class…) sont interprétées côté navigateur.
        Les données affichées (jours, semaineLabel…) viennent de data() dans le script ci-dessous.
    --}}
    <div id="app-creneaux">

        {{-- Titre + navigation semaine --}}
        <div class="d-flex align-items-center justify-content-between mb-3">
            <h2 class="h5 mb-0">Mes créneaux</h2>
            <div class="calendrier-nav">
                {{-- @click appelle la méthode precedente() définie dans methods{} --}}
                <button class="btn btn-outline-secondary btn-sm" @click="precedente">&lsaquo;</button>

                {{-- @{{ }} affiche une variable Vue (les {{ }} simples sont réservés à Blade) --}}
                <span class="semaine-label">@{{ semaineLabel }}</span>

                <button class="btn btn-outline-secondary btn-sm" @click="suivante">&rsaquo;</button>
            </div>
        </div>

        {{-- v-if affiche ce paragraphe UNIQUEMENT si chargement === true --}}
        <p v-if="chargement" class="text-muted">Chargement…</p>

        {{-- v-else affiche la grille UNIQUEMENT si chargement === false --}}
        <div v-else class="grille-wrapper">

            {{--
                :style est un binding dynamique — la valeur est calculée par Vue.
                On définit le nombre de colonnes CSS selon le nombre de jours reçus de l'API.
                Résultat CSS généré : "grid-template-columns: 56px repeat(7, 1fr)"
            --}}
            <div class="grille" :style="{ gridTemplateColumns: '56px repeat(' + jours.length + ', 1fr)' }">

                {{-- Ligne d'en-têtes : cellule vide (colonne des heures) + un en-tête par jour --}}
                <div></div>

                {{--
                    v-for="jour in jours" : Vue répète cette div pour chaque élément du tableau jours[].
                    À chaque tour, la variable "jour" contient l'élément courant du tableau.
                    Ici jours[] contient 7 éléments → 7 divs sont générées.
                    jour.label contient le texte affiché (ex. "Lun. 07/07").

                    Équivalent en PHP :
                        foreach ($jours as $jour) {
                            echo '<div class="grille-entete">' . $jour['label'] . '</div>';
                        }
                --}}
                <div v-for="jour in jours" class="grille-entete">@{{ jour.label }}</div>

                {{--
                    v-for="(slot, index) in jours[0].slots" : on itère sur les créneaux du premier jour
                    pour récupérer la liste des heures de la journée (identique pour tous les jours).
                    "slot"  = l'élément courant  (ex. { heure: "09:00", statut: "libre", prestation: null })
                    "index" = sa position (0, 1, 2…) — utilisé pour lire le même créneau dans chaque jour.

                    <template> est une balise Vue invisible : elle regroupe plusieurs éléments
                    sans ajouter de div inutile dans le HTML final.
                --}}
                <template v-for="(slot, index) in jours[0].slots">

                    {{-- Colonne 1 : heure du créneau (identique pour tous les jours) --}}
                    <div class="grille-heure">@{{ slot.heure }}</div>

                    {{--
                        v-for="jour in jours" : pour chaque jour, on affiche la cellule
                        du créneau à la position "index" dans son tableau de slots.
                        Exemple pour index=2 (09:00) : jour.slots[2] donne le créneau 09:00 de ce jour.

                        :class construit dynamiquement la classe CSS selon le statut retourné par l'API :
                            statut "libre"          → class "creneau creneau-libre"   (vert clair)
                            statut "occupe"         → class "creneau creneau-occupe"  (gris)
                            statut "ma_reservation" → class "creneau creneau-ma_reservation" (bleu)
                            statut "valide"         → class "creneau creneau-valide"  (vert foncé)

                        @click appelle clicCreneau() en lui passant les données du créneau cliqué.
                    --}}
                    <div
                        v-for="jour in jours"
                        :class="'creneau creneau-' + jour.slots[index].statut"
                        @click="clicCreneau(jour.slots[index])"
                        style="cursor: pointer;"
                    >
                        <span class="c-heure">@{{ jour.slots[index].heure }}</span>
                        <span class="c-label">@{{ labelStatut(jour.slots[index]) }}</span>
                    </div>

                </template>

            </div>
        </div>
    </div>
@endsection

@push('scripts')
<script src="/js/vue.global.prod.js"></script>
<script>
    /**
     * Application Vue.js — Grille de créneaux
     *
     * Cette app gère uniquement le bloc #app-creneaux.
     * Elle charge les créneaux via l'API interne GET /espace/creneaux?debut=Y-m-d
     * et permet de naviguer de plage en plage sans rechargement de page.
     *
     * Pour étendre cette app (ex. modal de réservation, filtre par prestation),
     * ajouter les propriétés dans data() et les méthodes dans methods{}.
     */
    const { createApp } = Vue;

    createApp({

        /**
         * data() — Données réactives de l'application
         *
         * Ces propriétés sont "réactives" : dès qu'une valeur change,
         * Vue met à jour automatiquement la partie du template qui l'utilise.
         * Pas besoin de toucher le DOM manuellement.
         */
        data() {
            return {
                // Tableau de jours retourné par l'API.
                // Chaque jour contient : { date, label, slots: [{ heure, statut, prestation }] }
                // Voir la structure complète dans EspaceController::creneaux()
                jours: [],

                // Libellé de la plage affiché dans la navigation (ex. "01 juillet – 07 juillet 2026")
                semaineLabel: '',

                // Date de début de la plage actuellement affichée (format Y-m-d).
                // Utilisée par precedente() et suivante() pour calculer la plage suivante.
                debutActuel: '',

                // Indicateur de chargement : true pendant le fetch, false une fois les données reçues.
                // Le template affiche "Chargement…" ou la grille selon cette valeur.
                chargement: true,
            };
        },

        /**
         * mounted() — Cycle de vie Vue
         *
         * Cette méthode est appelée automatiquement par Vue une seule fois,
         * juste après que le composant a été inséré dans la page (le DOM est prêt).
         * C'est ici qu'on déclenche le premier chargement des données.
         */
        mounted() {
            // On démarre à J-1 (hier) pour que l'utilisateur voie aussi sa veille
            this.charger(this.hier());
        },

        /**
         * methods{} — Actions disponibles dans le composant
         *
         * Ces méthodes peuvent être appelées depuis le template avec @click="nomMethode()"
         * ou depuis d'autres méthodes avec this.nomMethode().
         */
        methods: {

            /**
             * Retourne la date d'hier au format Y-m-d (ex. "2026-07-01").
             * new Date() = aujourd'hui, setDate(getDate() - 1) = hier.
             * toISOString() donne "2026-07-01T00:00:00.000Z", .slice(0, 10) garde "2026-07-01".
             */
            hier() {
                const date = new Date();
                date.setDate(date.getDate() - 1);
                return date.toISOString().slice(0, 10);
            },

            /**
             * Appelle l'API /espace/creneaux et met à jour les données de la grille.
             *
             * async/await permet d'attendre la réponse du serveur sans bloquer la page.
             * fetch() envoie la requête HTTP, .json() décode la réponse JSON.
             * Une fois les données reçues, Vue met à jour le template automatiquement.
             *
             * @param {string} debut  Date de départ au format Y-m-d
             */
            async charger(debut) {
                this.chargement = true; // affiche "Chargement…" dans le template

                const reponse = await fetch(`{{ route('espace.creneaux') }}?debut=${debut}`);
                const data    = await reponse.json();

                // On met à jour les données — Vue re-rend la grille automatiquement
                this.jours        = data.jours;
                this.semaineLabel = data.semaine;
                this.debutActuel  = data.debut;

                this.chargement = false; // masque "Chargement…", affiche la grille
            },

            /**
             * Recule la grille de 7 jours.
             * On crée un objet Date à partir de debutActuel, on retire 7 jours,
             * puis on recharge la grille avec cette nouvelle date.
             */
            precedente() {
                const date = new Date(this.debutActuel);
                date.setDate(date.getDate() - 7);
                this.charger(date.toISOString().slice(0, 10));
            },

            /**
             * Avance la grille de 7 jours (même logique que precedente).
             */
            suivante() {
                const date = new Date(this.debutActuel);
                date.setDate(date.getDate() + 7);
                this.charger(date.toISOString().slice(0, 10));
            },

            /**
             * Retourne le texte à afficher dans une cellule selon le statut du créneau.
             * Appelée depuis le template : @{{ labelStatut(slot) }}
             *
             * @param  {object} slot  { heure, statut, prestation }
             * @return {string}
             */
            labelStatut(slot) {
                if (slot.statut === 'libre')  return 'Libre';
                if (slot.statut === 'occupe') return 'Occupé';
                // Pour ma_reservation et valide, on affiche le nom de la prestation réservée
                return slot.prestation;
            },

            /**
             * Gère le clic sur un créneau.
             * Appelée depuis le template : @click="clicCreneau(slot)"
             *
             * Comportement actuel :
             *   - Réservation de l'utilisateur → redirige vers la page QR code
             *   - Autre statut              → affiche l'heure dans la console (développement)
             *
             * TODO : ouvrir une modale, proposer une réservation, afficher un détail, etc.
             *
             * @param {object} slot  { heure, statut, prestation }
             */
            clicCreneau(slot) {
                if (slot.statut === 'ma_reservation' || slot.statut === 'valide') {
                    // L'utilisateur clique sur sa propre réservation → page QR code
                    window.location.href = '{{ route('espace.qrcode') }}';
                } else {
                    // Créneau libre ou occupé par quelqu'un d'autre → log console pour l'instant
                    console.log(slot.heure);
                }
            },

        },

    }).mount('#app-creneaux');
    // .mount() indique à Vue quel élément HTML il doit contrôler (ici #app-creneaux)
</script>
@endpush
