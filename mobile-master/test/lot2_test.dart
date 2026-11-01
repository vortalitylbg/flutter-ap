import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/models/usr.dart';
import 'package:resachev/screens/main_app/historique_client.dart';
import 'package:resachev/screens/main_app/param_app.dart';
import 'package:resachev/theme/app_theme.dart';
import 'package:resachev/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tests des règles métier du lot 2 (US 2.1, 2.3, 2.4, 2.5 et 2.6).

Reservation _reservation({
  String id = '12',
  String date = '07/07/2026',
  String heure = '09:00',
  bool? presence = false,
  Map<String, dynamic>? extra,
}) {
  return Reservation.fromJson(<String, dynamic>{
    'idreservation': id,
    'datedebut': date,
    'heuredebut': heure,
    'validationpresence': presence,
    'prestation': 'Enregistrement',
    'utilisateur': <String, dynamic>{
      'idutilisateur': 7,
      'nom': 'Dupont',
      'prenom': 'Camille',
      'email': 'camille@studio.fr',
    },
    ...?extra,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DateTime debut = DateTime(2026, 7, 7, 9, 0);

  group('US 2.3 - fenêtre de validité du QR code', () {
    test('le QR code est valide 30 minutes avant le début', () {
      final Reservation r = _reservation();
      expect(
        r.verifierValiditeQr(debut.subtract(const Duration(minutes: 30))),
        isNull,
      );
    });

    test('le QR code est refusé plus tôt', () {
      final Reservation r = _reservation();
      final String? motif = r.verifierValiditeQr(
        debut.subtract(const Duration(minutes: 31)),
      );
      expect(motif, isNotNull);
      expect(motif!.contains('30 minutes avant'), isTrue);
    });

    test('le QR code reste valide 45 minutes après le début', () {
      final Reservation r = _reservation();
      expect(
        r.verifierValiditeQr(debut.add(const Duration(minutes: 45))),
        isNull,
      );
    });

    test('le QR code expire au-delà de 45 minutes', () {
      final Reservation r = _reservation();
      final String? motif = r.verifierValiditeQr(
        debut.add(const Duration(minutes: 46)),
      );
      expect(motif, isNotNull);
      expect(motif!.contains('expiré'), isTrue);
    });

    test('un QR code de la veille est refusé', () {
      final Reservation r = _reservation();
      expect(
        r.verifierValiditeQr(debut.subtract(const Duration(days: 1))),
        isNotNull,
      );
    });

    test('un QR code déjà validé est refusé', () {
      final Reservation r = _reservation(presence: true);
      final String? motif = r.verifierValiditeQr(debut);
      expect(motif, isNotNull);
      expect(motif!.contains('déjà été validée'), isTrue);
    });
  });

  group('US 2.6 - conditions d\'annulation', () {
    final DateTime maintenant = DateTime(2026, 7, 7, 8, 0);

    test('un rendez-vous à venir non honoré peut être annulé', () {
      final Reservation r = _reservation();
      expect(r.motifAnnulationImpossible(maintenant), isNull);
      expect(r.peutEtreAnnulee(maintenant), isTrue);
    });

    test('un rendez-vous passé ne peut plus être annulé', () {
      final Reservation r = _reservation();
      final String? motif = r.motifAnnulationImpossible(
        DateTime(2026, 7, 7, 9, 30),
      );
      expect(motif, isNotNull);
      expect(motif!.contains('déjà commencé'), isTrue);
    });

    test('un rendez-vous déjà honoré ne peut plus être annulé', () {
      final Reservation r = _reservation(presence: true);
      final String? motif = r.motifAnnulationImpossible(maintenant);
      expect(motif, isNotNull);
      expect(motif!.contains('déjà validée'), isTrue);
    });
  });

  group('US 2.5 - informations complémentaires', () {
    test('montant, durée, heure de fin et participants sont exploités', () {
      final Reservation r = _reservation(
        extra: <String, dynamic>{
          'montant': '45,00 €',
          'duree': '1:30',
          'participants': 3,
        },
      );

      expect(r.montant, 45.0);
      expect(r.dureeMinutes, 90);
      expect(r.dureeAffichee, '1 h 30');
      expect(r.participants, 3);
      expect(r.participantsAffiches, '3 participants');
      expect(r.finTheorique, DateTime(2026, 7, 7, 10, 30));
      expect(r.montantAffiche, '45,00 €');
    });

    test('une heure de fin fournie par l\'API est prioritaire', () {
      final Reservation r = _reservation(
        extra: <String, dynamic>{'heurefin': '11:15', 'duree': 60},
      );
      expect(r.finTheorique, DateTime(2026, 7, 7, 11, 15));
    });

    test('les informations absentes restent explicites', () {
      final Reservation r = _reservation();
      expect(r.montantAffiche, 'Non renseigné');
      expect(r.dureeAffichee, 'Non renseignée');
      expect(r.participantsAffiches, 'Non renseigné');
      expect(r.finTheorique, isNull);
    });
  });

  group('US 2.1 - journée, recherche et tri', () {
    test('seuls les rendez-vous du jour sélectionné sont retenus', () {
      final Reservation duJour = _reservation(id: '1');
      final Reservation autreJour = _reservation(id: '2', date: '08/07/2026');

      expect(duJour.estLeJour(DateTime(2026, 7, 7)), isTrue);
      expect(autreJour.estLeJour(DateTime(2026, 7, 7)), isFalse);
    });

    test('la recherche porte sur le client ou la prestation', () {
      final Reservation r = _reservation();
      expect(r.correspondRecherche('camille'), isTrue);
      expect(r.correspondRecherche('enregistrement'), isTrue);
      expect(r.correspondRecherche('mixage'), isFalse);
    });

    test('le tri par heure de début est respecté dans les deux sens', () {
      final Reservation matin = _reservation(id: '1', heure: '09:00');
      final Reservation apresMidi = _reservation(id: '2', heure: '15:00');
      final List<Reservation> liste = <Reservation>[apresMidi, matin];

      liste.sort((a, b) => a.comparerParDateEtHeure(b));
      expect(liste.first.idreservation, '1');

      liste.sort((a, b) => b.comparerParDateEtHeure(a));
      expect(liste.first.idreservation, '2');
    });
  });

  group('US 2.4 - mode clair et sombre', () {
    test('le thème sombre est proposé et mémorisé', () async {
      expect(AppTheme.dark.brightness, Brightness.dark);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      await ThemeController.definirSombre(true);
      expect(ThemeController.sombre, isTrue);

      ThemeController.mode.value = ThemeMode.light;
      await ThemeController.charger();
      expect(ThemeController.sombre, isTrue);

      await ThemeController.definirSombre(false);
      expect(ThemeController.sombre, isFalse);
    });

    test('la palette suit le mode appliqué', () {
      AppColors.definirMode(false);
      final Color fondClair = AppColors.fond;
      AppColors.definirMode(true);
      expect(AppColors.fond, isNot(fondClair));
      expect(AppTheme.dark.scaffoldBackgroundColor, isNot(fondClair));
      AppColors.definirMode(false);
    });

    testWidgets('le paramètre des paramètres bascule le mode sombre', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      ThemeController.mode.value = ThemeMode.light;

      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ParamApp(
            utilisateurInitial: User(
              idutilisateur: 3,
              nom: 'Dupont',
              prenom: 'Camille',
              email: 'camille.dupont@studio.fr',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // US 2.4, règle 1 : le mode se change depuis les paramètres.
      await tester.tap(find.text('Mode sombre'));
      await tester.pump();

      expect(ThemeController.sombre, isTrue);
    });

    testWidgets('un écran déjà affiché suit le changement de mode', (
      WidgetTester tester,
    ) async {
      ThemeController.mode.value = ThemeMode.light;
      final Reservation r = _reservation(date: '07/07/2026');

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (BuildContext context, ThemeMode mode, Widget? child) {
            AppColors.definirMode(mode == ThemeMode.dark);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: HistoriqueClient(
                nomClient: 'Camille Dupont',
                reservations: <Reservation>[r],
              ),
            );
          },
        ),
      );
      await tester.pump();

      final Color fondClair = AppColors.fond;
      expect(AppColors.estSombre, isFalse);

      ThemeController.mode.value = ThemeMode.dark;
      // MaterialApp anime le changement de thème : on laisse la transition
      // se terminer avant de vérifier l'écran.
      await tester.pumpAndSettle();

      final BuildContext ecran = tester.element(find.byType(HistoriqueClient));
      expect(Theme.of(ecran).brightness, Brightness.dark);
      expect(AppColors.estSombre, isTrue);
      expect(AppColors.fond, isNot(fondClair));

      ThemeController.mode.value = ThemeMode.light;
    });
  });
}
