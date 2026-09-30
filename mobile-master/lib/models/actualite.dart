import 'package:flutter/material.dart';

// US 1.1 : une actualité publiée par l'organisation (SoundBox Studio).
// Les actualités sont des données de contenu, pas des données métier : elles
// sont déclarées dans lib/data/organisation.dart et non chargées depuis l'API.

class Actualite {
  /// Titre de l'annonce.
  final String titre;

  /// Date de publication, déjà rédigée en français (ex. « 12 septembre 2026 »).
  final String date;

  /// Rubrique : « Studio », « Équipe », « Événement » ou « Offre ».
  final String categorie;

  /// Résumé de l'annonce affiché sur la page d'accueil.
  final String resume;

  /// Icône représentative de la rubrique.
  final IconData icone;

  const Actualite({
    required this.titre,
    required this.date,
    required this.categorie,
    required this.resume,
    required this.icone,
  });
}
