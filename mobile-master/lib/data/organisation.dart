import 'package:flutter/material.dart';
import 'package:resachev/models/actualite.dart';

// US 1.1 : contenu éditorial de l'organisation « SoundBox Studio ».
//
// Ces données décrivent l'identité et l'activité du studio. Elles sont
// statiques et séparées du modèle métier : le parc de séances, lui, est
// toujours chargé depuis l'API via ReservationApi.listerReservations().

/// Une prestation proposée par le studio.
class ServiceStudio {
  /// Intitulé de la prestation, tel qu'il est annoncé aux clients.
  final String titre;

  /// Description courte de la prestation.
  final String description;

  /// Icône Material représentative.
  final IconData icone;

  const ServiceStudio({
    required this.titre,
    required this.description,
    required this.icone,
  });
}

/// Contenus de l'organisation affichés sur la page d'accueil.
class Organisation {
  Organisation._();

  // ---------------------------------------------------------------------------
  // Identité (US 1.1.3 : le nom et un visuel de l'organisation)
  // ---------------------------------------------------------------------------

  /// Nom de l'organisation.
  static const String nom = 'SoundBox Studio';

  /// Accroche affichée sous le nom.
  static const String slogan = 'Studio d\'enregistrement, mixage & mastering';

  /// Raison sociale, affichée dans le pied de page de l'accueil.
  static const String raisonSociale = 'SoundBox Studio SARL';

  /// Adresse du studio.
  static const String adresse = '14 rue des Ondes, 75011 Paris';

  /// Téléphone du studio.
  static const String telephone = '01 84 80 22 10';

  /// Horaires d'ouverture du studio.
  static const String horaires = 'Du lundi au samedi, 9 h - 22 h';

  /// Illustration du studio utilisée en bannière.
  static const String image = 'assets/images/studio-musique.jpg.png';

  // ---------------------------------------------------------------------------
  // Présentation (US 1.1.3 : une brève description des services)
  // ---------------------------------------------------------------------------

  /// Description de l'organisation et de l'activité du studio.
  static const String description =
      'SoundBox Studio est un studio d\'enregistrement indépendant installé '
      'à Paris. Deux cabines SHRM, une régie traitée acoustiquement et une '
      'salle de répétition équipée mettent à disposition des artistes, des '
      'podcasters et des groupes de toute la région.';

  /// Explication du rôle de l'application, dans le vocabulaire du studio.
  static const String descriptionApplication =
      'SoundBox Booking est l\'outil de réception du studio : il centralise '
      'les séances du jour, vérifie la présence des artistes et gère les '
      'informations du personnel.';

  /// Prestations proposées par le studio.
  static const List<ServiceStudio> services = <ServiceStudio>[
    ServiceStudio(
      titre: 'Enregistrement',
      description:
          'Prise de voix et d\'instruments en multipiste dans les cabines A et B.',
      icone: Icons.mic_none,
    ),
    ServiceStudio(
      titre: 'Mixage & mastering',
      description:
          'Écoute en monitoring de référence et mastering stéréo certifié.',
      icone: Icons.tune,
    ),
    ServiceStudio(
      titre: 'Location de salle',
      description:
          'Répétition et songwriting dans une salle équipée.',
      icone: Icons.meeting_room_outlined,
    ),
    ServiceStudio(
      titre: 'Coaching musical',
      description:
          'Cours de chant, de guitare et de production musicale.',
      icone: Icons.music_note,
    ),
    ServiceStudio(
      titre: 'Podcast & voix off',
      description:
          'Enregistrement multipiste jusqu\'à quatre intervenants.',
      icone: Icons.podcasts,
    ),
    ServiceStudio(
      titre: 'Location de matériel',
      description:
          'Tables de mixage, microphones et instruments de studio à l\'heure.',
      icone: Icons.settings_voice,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Actualités (US 1.1.3 : les nouvelles informations de l'organisation)
  // ---------------------------------------------------------------------------

  /// Dernières nouvelles publiées par le studio, de la plus récente à la plus
  /// ancienne.
  static const List<Actualite> actualites = <Actualite>[
    Actualite(
      titre: 'Cabine B entièrement rééquippée',
      date: '12 septembre 2026',
      categorie: 'Studio',
      resume:
          'Monitoring Tannoy Reveal, ligne de patch complète et micro à lampe : '
          'la cabine B est de nouveau disponible à la réservation dès le '
          '15 septembre.',
      icone: Icons.settings_input_component,
    ),
    Actualite(
      titre: 'Malik Ferrand rejoint l\'équipe',
      date: '5 septembre 2026',
      categorie: 'Équipe',
      resume:
          'Notre nouvel ingé du son prend en charge les sessions de mixage et de '
          'mastering. Bienvenue au studio !',
      icone: Icons.group_add_outlined,
    ),
    Actualite(
      titre: 'Nuit du mix : 20 % sur le mastering',
      date: '2 septembre 2026',
      categorie: 'Offre',
      resume:
          'Toutes les sessions de mastering réservées avant le 30 septembre '
          'bénéficient d\'une remise de 20 % sur le tarif de nuit.',
      icone: Icons.local_offer_outlined,
    ),
    Actualite(
      titre: 'Portes ouvertes le 27 septembre',
      date: '30 août 2026',
      categorie: 'Événement',
      resume:
          'Visite libre du studio de 11 h à 19 h : présentation des cabines, '
          'essais de micro et séance d\'écoute collective. Entrée libre.',
      icone: Icons.celebration_outlined,
    ),
    Actualite(
      titre: 'Session de songwriting collective',
      date: '22 août 2026',
      categorie: 'Studio',
      resume:
          'Six places ouvertes pour une session d\'écriture organisée par '
          'l\'atelier du mercredi soir. Inscriptions auprès de l\'accueil.',
      icone: Icons.groups_outlined,
    ),
  ];
}
