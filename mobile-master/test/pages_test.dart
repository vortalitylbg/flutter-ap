import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resachev/models/usr.dart';
import 'package:resachev/screens/main_app/accueil_app.dart';
import 'package:resachev/screens/main_app/modifier_informations.dart';
import 'package:resachev/screens/main_app/param_app.dart';
import 'package:resachev/theme/app_theme.dart';

// Tests de rendu des écrans réécrits pour le lot 1.
// Ils vérifient que les éléments attendus par les scénarios d'acceptation
// s'affichent réellement et qu'aucune erreur de construction ne survient.

Widget _envelopper(Widget enfant) {
  return MaterialApp(theme: AppTheme.light, home: enfant);
}

/// Surface de test haute, pour que le formulaire tienne sans défilement.
Future<void> _grandEcran(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(500, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('US 1.1 - Rendu de la page d\'accueil', () {
    testWidgets('affiche le nom, le slogan, les prestations et les actualités',
        (WidgetTester tester) async {
      await _grandEcran(tester);
      await tester.pumpWidget(_envelopper(const Accueil()));
      await tester.pumpAndSettle();

      // Identité de l'organisation (règle métier 1.1.3).
      expect(find.text('SoundBox Studio'), findsWidgets);
      expect(
        find.text('Studio d\'enregistrement, mixage & mastering'),
        findsOneWidget,
      );

      // Présentation des services proposés.
      expect(find.text('Nos prestations'), findsOneWidget);
      expect(find.text('Enregistrement'), findsWidgets);
      expect(find.text('Podcast & voix off'), findsOneWidget);

      // Nouvelles informations de l'organisation : la section se trouve sous
      // la ligne de flottaison, il faut faire défiler la page.
      await tester.scrollUntilVisible(
        find.text('Dernières actualités du studio'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Dernières actualités du studio'), findsOneWidget);
      expect(find.text('Cabine B entièrement rééquippée'), findsOneWidget);

      // Aucun contenu générique résiduel (règle métier 1.1.1).
      expect(find.textContaining('Lorem ipsum'), findsNothing);
      expect(find.textContaining('resachev'), findsNothing);
    });

    testWidgets('le visuel du studio est affiché', (WidgetTester tester) async {
      await _grandEcran(tester);
      await tester.pumpWidget(_envelopper(const Accueil()));
      await tester.pumpAndSettle();

      // Le logo et la photo du studio composent le bandeau d'identité.
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('US 1.2 - Rendu de la page des paramètres', () {
    testWidgets('la zone d\'informations du compte est délimitée et titrée',
        (WidgetTester tester) async {
      await _grandEcran(tester);
      await tester.pumpWidget(_envelopper(ParamApp(
        utilisateurInitial: User(
          idutilisateur: 3,
          nom: 'Dupont',
          prenom: 'Camille',
          email: 'camille.dupont@studio.fr',
        ),
      )));
      // Les informations connues sont affichées immédiatement, sans attendre
      // la fin du chargement asynchrone.
      await tester.pump();

      // Zone d'informations utilisateur identifiable (règle métier 1.2.2).
      expect(find.text('Informations du compte'), findsOneWidget);
      // L'adresse email fait partie des informations affichées (règle 1.2.1).
      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('camille.dupont@studio.fr'), findsOneWidget);
      expect(find.text('Prénom'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Identifiant'), findsOneWidget);

      // RG 1.4.1 : le bouton d'accès à la modification est présent.
      expect(find.text('Modifier mes informations'), findsOneWidget);
      // RG 1.4.5 : le bouton de déconnexion est présent.
      expect(find.text('Se déconnecter'), findsOneWidget);
    });
  });

  group('US 1.4 - Rendu de la page de modification', () {
    Future<void> afficherFormulaire(WidgetTester tester) async {
      await _grandEcran(tester);
      await tester.pumpWidget(_envelopper(
        ModifierInformations(
          utilisateur: User(
            idutilisateur: 3,
            nom: 'Dupont',
            prenom: 'Camille',
            email: 'camille.dupont@studio.fr',
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('affiche les trois champs pré-remplis et les deux boutons',
        (WidgetTester tester) async {
      await afficherFormulaire(tester);

      expect(find.text('Mes informations'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nom'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Prénom'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Adresse email'),
        findsOneWidget,
      );

      // Les valeurs actuelles sont pré-remplies dans les champs.
      expect(find.text('Dupont'), findsOneWidget);
      expect(find.text('Camille'), findsOneWidget);
      expect(find.text('camille.dupont@studio.fr'), findsOneWidget);

      // RG 1.4.2 : bouton de validation et bouton d'annulation.
      expect(find.text('Valider les modifications'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('refuse un champ vide, un chiffre dans le nom et un email invalide',
        (WidgetTester tester) async {
      await afficherFormulaire(tester);

      final Finder champNom = find.widgetWithText(TextFormField, 'Nom');
      final Finder champPrenom = find.widgetWithText(TextFormField, 'Prénom');
      final Finder champEmail =
          find.widgetWithText(TextFormField, 'Adresse email');
      final Finder boutonValider = find.text('Valider les modifications');

      // 1. Champs vides : les trois erreurs « obligatoire » apparaissent.
      await tester.enterText(champNom, '');
      await tester.enterText(champPrenom, '');
      await tester.enterText(champEmail, '');
      await tester.tap(boutonValider);
      await tester.pump();

      expect(find.text('Le champ « Nom » est obligatoire.'), findsOneWidget);
      expect(
        find.text('Le champ « Prénom » est obligatoire.'),
        findsOneWidget,
      );
      expect(
        find.text('Le champ « Adresse email » est obligatoire.'),
        findsOneWidget,
      );

      // 2. Un chiffre dans le nom est refusé.
      await tester.enterText(champNom, 'Dupont2');
      await tester.enterText(champPrenom, 'Camille');
      await tester.enterText(champEmail, 'camille.dupont@studio.fr');
      await tester.tap(boutonValider);
      await tester.pump();

      expect(
        find.text('Le champ « Nom » ne doit pas contenir de chiffre.'),
        findsOneWidget,
      );

      // 3. Un chiffre dans le prénom est refusé.
      await tester.enterText(champNom, 'Dupont');
      await tester.enterText(champPrenom, 'Camille3');
      await tester.tap(boutonValider);
      await tester.pump();

      expect(
        find.text('Le champ « Prénom » ne doit pas contenir de chiffre.'),
        findsOneWidget,
      );

      // 4. Un format d'email invalide est refusé.
      await tester.enterText(champPrenom, 'Camille');
      await tester.enterText(champEmail, 'camille.dupont');
      await tester.tap(boutonValider);
      await tester.pump();

      expect(
        find.text('Le format de l\'adresse email est invalide.'),
        findsOneWidget,
      );
    });
  });
}
