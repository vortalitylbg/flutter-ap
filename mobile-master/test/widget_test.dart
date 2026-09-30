import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resachev/data/organisation.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/theme/app_theme.dart';

void main() {
  group('US 1.1 - Thème SoundBox Studio', () {
    test('le nom et le slogan de l\'organisation sont renseignés', () {
      expect(Organisation.nom, 'SoundBox Studio');
      expect(Organisation.slogan, isNotEmpty);
      expect(Organisation.description, isNotEmpty);
    });

    test('la page d\'accueil présente des services et des actualités', () {
      expect(Organisation.services, isNotEmpty);
      expect(Organisation.actualites, isNotEmpty);

      for (final ServiceStudio service in Organisation.services) {
        expect(service.titre, isNotEmpty);
        expect(service.description, isNotEmpty);
      }
    });

    test('la charte reprend les couleurs de la page de connexion', () {
      expect(AppColors.fond, const Color(0xFFf3f4f6));
      expect(AppColors.principal, const Color(0xFF344d59));
      expect(AppColors.secondaire, const Color(0xFF7a90a4));
      expect(AppColors.texte, const Color(0xFF1A1A1A));
    });
  });

  group('US 1.3 - Enregistrement du client', () {
    Reservation reservationAvecClient(String? nom, String? prenom) {
      return Reservation.fromJson(<String, dynamic>{
        'idreservation': '1',
        'datedebut': '07/07/2026',
        'heuredebut': '09:00',
        'validationpresence': false,
        'prestation': 'Enregistrement',
        'utilisateur': <String, dynamic>{
          'idutilisateur': 7,
          'nom': nom,
          'prenom': prenom,
          'email': 'artiste@studio.fr',
        },
      });
    }

    test('un client dont l\'identité est complète est enregistré', () {
      final Reservation r = reservationAvecClient('Dupont', 'Camille');
      expect(r.clientEnregistre, isTrue);
      expect(r.nomClient, 'Camille Dupont');
    });

    test('un client sans identité n\'est pas enregistré', () {
      final Reservation sansNom = reservationAvecClient(null, 'Camille');
      final Reservation sansPrenom = reservationAvecClient('Dupont', '   ');
      final Reservation sansClient = Reservation.fromJson(<String, dynamic>{
        'idreservation': '2',
        'datedebut': '07/07/2026',
        'heuredebut': '10:00',
        'prestation': 'Mixage & mastering',
      });

      expect(sansNom.clientEnregistre, isFalse);
      expect(sansPrenom.clientEnregistre, isFalse);
      expect(sansClient.clientEnregistre, isFalse);
      expect(sansClient.nomClient, '');
    });

    test('le code couleur diffère selon l\'état du client', () {
      expect(AppColors.enregistreTexte, isNot(AppColors.nonEnregistreTexte));
      expect(AppColors.enregistreFond, isNot(AppColors.nonEnregistreFond));
    });
  });

  group('US 1.4 - Validation des informations', () {
    test('le format d\'email attendu est reconnu', () {
      expect(AppColors.formatEmail.hasMatch('prenom.nom@studio.fr'), isTrue);
      expect(AppColors.formatEmail.hasMatch('prenom+tag@studio-son.fr'), isTrue);
      expect(AppColors.formatEmail.hasMatch('sans-arobase'), isFalse);
      expect(AppColors.formatEmail.hasMatch('pasunformat@'), isFalse);
      expect(AppColors.formatEmail.hasMatch('@studio.fr'), isFalse);
    });

    test('les chiffres sont détectés dans un nom ou un prénom', () {
      expect(AppColors.chiffres.hasMatch('Jean2'), isTrue);
      expect(AppColors.chiffres.hasMatch('Camille'), isFalse);
    });
  });
}
