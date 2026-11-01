import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resachev/models/entree_attente.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/screens/main_app/detail_reservation.dart';
import 'package:resachev/screens/main_app/liste_attente.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';

// Lot 3 : règles métier de la liste d'attente (US 3.1) et des réservations
// récurrentes (US 3.2).

Reservation reservationComplete() {
  return Reservation.fromJson(<String, dynamic>{
    'idreservation': 42,
    'datedebut': '15/12/2026',
    'heuredebut': '09:00',
    'duree': 90,
    'prestation': 'Enregistrement',
    'participants': 8,
    'capacite': 8,
    'client': <String, dynamic>{'nom': 'Martin', 'prenom': 'Jean'},
  });
}

void main() {
  group('US 3.1 - capacité du créneau', () {
    test('un créneau dont les places sont prises est complet', () {
      final Reservation reservation = reservationComplete();

      expect(reservation.estComplete, isTrue);
      expect(reservation.placesRestantes, 0);
      expect(reservation.placesAffichees, '0 / 8 places disponibles');
      expect(reservation.listeAttenteDisponible, isTrue);
    });

    test('les places restantes transmises par l\'API sont prioritaires', () {
      final Reservation reservation = Reservation.fromJson(<String, dynamic>{
        'idreservation': 43,
        'datedebut': '15/12/2026',
        'heuredebut': '11:00',
        'participants': 8,
        'capacite': 8,
        'placesrestantes': 2,
      });

      expect(reservation.estComplete, isFalse);
      expect(reservation.placesRestantes, 2);
    });

    test('sans capacité connue, le créneau n\'est pas déclaré complet', () {
      final Reservation reservation = Reservation.fromJson(<String, dynamic>{
        'idreservation': 44,
        'datedebut': '15/12/2026',
        'heuredebut': '14:00',
        'participants': 4,
      });

      expect(reservation.estComplete, isFalse);
      expect(reservation.placesRestantes, isNull);
      expect(reservation.placesAffichees, 'Non renseignées');
      expect(reservation.listeAttenteDisponible, isFalse);
    });

    test('le nombre d\'inscrits en attente peut venir d\'un tableau', () {
      final Reservation reservation = Reservation.fromJson(<String, dynamic>{
        'idreservation': 45,
        'datedebut': '15/12/2026',
        'heuredebut': '16:00',
        'capacite': 6,
        'participants': 6,
        'listeattente': <dynamic>[
          <String, dynamic>{'idattente': 1},
          <String, dynamic>{'idattente': 2},
          <String, dynamic>{'idattente': 3},
        ],
      });

      expect(reservation.nombreListeAttente, 3);
      expect(reservation.listeAttenteDisponible, isTrue);
    });
  });

  group('US 3.1 - entrées de la liste d\'attente', () {
    test('le client est affiché au format Prénom NOM, avec son statut', () {
      final EntreeAttente entree = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 7,
        'idreservation': 42,
        'client': <String, dynamic>{
          'nom': 'Martin',
          'prenom': 'Jean',
          'email': 'jean.martin@exemple.fr',
        },
        'statut': 'proposee',
        'inscritle': '2026-12-01T09:15:00',
        'propositionexpirele': '2026-12-01T09:45:00',
      });

      expect(entree.nomClient, 'Jean Martin');
      expect(entree.email, 'jean.martin@exemple.fr');
      expect(entree.statut, StatutAttente.proposee);
      expect(entree.estProposee(DateTime(2026, 12, 1, 9, 30)), isTrue);
      expect(
        entree.libelleStatut(DateTime(2026, 12, 1, 9, 30)),
        'Place proposée jusqu’à 09:45',
      );
    });

    test('une proposition dépassée est expirée et n\'est plus active', () {
      final EntreeAttente entree = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 8,
        'idreservation': 42,
        'nomclient': 'Alice Durand',
        'statut': 'proposee',
        'propositionexpirele': '2026-12-01T09:45:00',
      });

      final DateTime maintenant = DateTime(2026, 12, 1, 10, 0);
      expect(entree.estProposee(maintenant), isFalse);
      expect(entree.estPropositionExpiree(maintenant), isTrue);
      expect(entree.libelleStatut(maintenant), 'Proposition expirée');
    });

    test('l\'ordre de passage suit le rang puis la date d\'inscription', () {
      final EntreeAttente premier = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 1,
        'idreservation': 42,
        'nomclient': 'Premier',
        'inscritle': '2026-12-01T08:00:00',
      });
      final EntreeAttente second = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 2,
        'idreservation': 42,
        'nomclient': 'Second',
        'inscritle': '2026-12-01T09:00:00',
      });

      expect(premier.comparerParOrdre(second), lessThan(0));

      final EntreeAttente prioritaire = EntreeAttente.fromJson(
        <String, dynamic>{
          'idattente': 3,
          'idreservation': 42,
          'nomclient': 'Prioritaire',
          'position': 1,
          'inscritle': '2026-12-01T10:00:00',
        },
      );
      expect(prioritaire.comparerParOrdre(premier), lessThan(0));
    });
  });

  group('US 3.2 - réservations récurrentes', () {
    test('une occurrence expose sa série et sa position', () {
      final Reservation reservation = Reservation.fromJson(<String, dynamic>{
        'idreservation': 50,
        'idrecurrence': 12,
        'recurrence': 'Chaque mardi',
        'finrecurrence': '15/12/2026',
        'numerooccurrence': 3,
        'nboccurrences': 8,
        'datedebut': '01/12/2026',
        'heuredebut': '18:00',
      });

      expect(reservation.estRecurrente, isTrue);
      expect(
        reservation.libelleRecurrenceAffiche,
        'Chaque mardi · jusqu\'au 15/12/2026',
      );
      expect(reservation.occurrenceAffichee, 'Occurrence 3 sur 8');
    });

    test('une réservation simple n\'est pas récurrente', () {
      final Reservation reservation = reservationComplete();

      expect(reservation.estRecurrente, isFalse);
      expect(reservation.occurrenceAffichee, isNull);
    });

    test('l\'annulation d\'une occurrence ne transmet pas de portée', () {
      expect(
        ReservationApi.corpsAnnulation(42, PorteeAnnulation.occurrence),
        <String, dynamic>{'idreservation': 42},
      );
    });

    test('l\'annulation d\'une série transmet la portée au serveur', () {
      expect(
        ReservationApi.corpsAnnulation(42, PorteeAnnulation.serie),
        <String, dynamic>{'idreservation': 42, 'portee': 'serie'},
      );
    });

    test('le périmètre est lisible par l\'employé', () {
      expect(PorteeAnnulation.occurrence.libelle, 'Cette séance uniquement');
      expect(PorteeAnnulation.serie.libelle, 'Toute la série');
    });

    test('copyWith conserve la série et la capacité', () {
      final Reservation reservation = Reservation.fromJson(<String, dynamic>{
        'idreservation': 51,
        'idrecurrence': 12,
        'recurrence': 'Chaque mardi',
        'datedebut': '01/12/2026',
        'heuredebut': '18:00',
        'capacite': 4,
        'participants': 4,
      });

      final Reservation miseAJour = reservation.copyWith(
        validationpresence: true,
      );

      expect(miseAJour.estRecurrente, isTrue);
      expect(miseAJour.estComplete, isTrue);
      expect(miseAJour.idrecurrence, '12');
    });
  });

  group('US 3.1 - écran de liste d\'attente', () {
    testWidgets('les inscrits sont affichés dans l\'ordre de passage', (
      WidgetTester tester,
    ) async {
      final EntreeAttente premier = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 1,
        'idreservation': 42,
        'nomclient': 'Alice Durand',
        'email': 'alice@exemple.fr',
        'statut': 'attente',
        'inscritle': '2026-12-01T08:00:00',
      });
      final EntreeAttente second = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 2,
        'idreservation': 42,
        'nomclient': 'Bob Martin',
        'email': 'bob@exemple.fr',
        'statut': 'attente',
        'inscritle': '2026-12-01T09:00:00',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ListeAttente(
            reservation: reservationComplete(),
            placeLiberee: true,
            chargeur: (String idreservation) async => <String, dynamic>{
              'ok': true,
              'entrees': <EntreeAttente>[second, premier],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice Durand'), findsOneWidget);
      expect(find.text('Bob Martin'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Alice Durand')).dy,
        lessThan(tester.getTopLeft(find.text('Bob Martin')).dy),
      );

      final ElevatedButton bouton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Proposer la place au suivant'),
      );
      expect(bouton.onPressed, isNotNull);
    });

    test('une proposition est déduite de sa date d\'expiration', () {
      final EntreeAttente entree = EntreeAttente.fromJson(<String, dynamic>{
        'idattente': 9,
        'idreservation': 42,
        'nomclient': 'Sans statut',
        'propositionexpirele': '2026-12-01T09:45:00',
      });

      expect(entree.statut, StatutAttente.proposee);
    });
  });

  group('US 3.2 - dialogue d\'annulation', () {
    testWidgets('une séance de série propose les deux périmètres', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final Reservation reservation = Reservation.fromJson(<String, dynamic>{
        'idreservation': 50,
        'idrecurrence': 12,
        'recurrence': 'Chaque mardi',
        'finrecurrence': '15/12/2026',
        'numerooccurrence': 3,
        'nboccurrences': 8,
        'datedebut': '01/12/2026',
        'heuredebut': '18:00',
        'prestation': 'Enregistrement',
      });

      await tester.pumpWidget(
        MaterialApp(home: DetailReservation(reservation: reservation)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Occurrence 3 sur 8'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Annuler la réservation'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cette séance'), findsOneWidget);
      expect(find.text('Toute la série'), findsOneWidget);

      await tester.tap(find.text('Toute la série'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler la série'), findsOneWidget);
      expect(
        find.textContaining('Toutes les occurrences à venir'),
        findsOneWidget,
      );
    });
  });
}
