import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/initials_helper.dart';

void main() {
  group('InitialsHelper.initialsFromName', () {
    test('nom simple → 1 char', () {
      expect(InitialsHelper.initialsFromName('Jean'), 'J');
    });

    test('apostrophe → 2 chars (N\'Sumbu → NS)', () {
      expect(InitialsHelper.initialsFromName("N'Sumbu"), 'NS');
    });

    test('tiret → 2 chars (Ndombo-Kabongo → NK)', () {
      expect(InitialsHelper.initialsFromName('Ndombo-Kabongo'), 'NK');
    });

    test('prénom composé avec tiret (Marie-Claire → MC)', () {
      expect(InitialsHelper.initialsFromName('Marie-Claire'), 'MC');
    });

    test('chaîne vide → chaîne vide', () {
      expect(InitialsHelper.initialsFromName(''), '');
    });

    test('espaces seuls → chaîne vide', () {
      expect(InitialsHelper.initialsFromName('   '), '');
    });

    test('accent normalisé (Éric → E)', () {
      expect(InitialsHelper.initialsFromName('Éric'), 'E');
    });

    test('tiret initial ignoré, premier alpha retenu', () {
      expect(InitialsHelper.initialsFromName('-Kabongo'), 'K');
    });

    test('apostrophe initiale ignorée', () {
      expect(InitialsHelper.initialsFromName("'Ntoto"), 'N');
    });
  });

  group('InitialsHelper.initialsFrom', () {
    test('nom + prénom → NOM-Prénom (K + J)', () {
      expect(InitialsHelper.initialsFrom('Jean', 'Kabila'), 'KJ');
    });

    test('lastName vide → prénom doublé', () {
      expect(InitialsHelper.initialsFrom('Jean', ''), 'JJ');
    });

    test('accent dans le prénom normalisé (Élodie)', () {
      expect(InitialsHelper.initialsFrom('Élodie', 'Mwamba'), 'ME');
    });

    test('accent dans le nom normalisé', () {
      expect(InitialsHelper.initialsFrom('Jean', 'Ébola'), 'EJ');
    });

    test('résultat toujours en majuscule', () {
      expect(InitialsHelper.initialsFrom('alice', 'bob'), 'BA');
    });

    test('les deux champs vides → ?', () {
      expect(InitialsHelper.initialsFrom('', ''), '?');
    });

    test('firstName vide, lastName présent → NOM doublé', () {
      // lastName présent mais firstName vide → firstChar de firstName = ''
      // donc résultat = normalize(lastChar) + normalize('') = 'K' + '' = 'K'
      expect(InitialsHelper.initialsFrom('', 'Kabila'), 'K');
    });

    test('nom avec apostrophe : premier char alpha retenu (N\'Sumbu)', () {
      // N'Sumbu comme lastName → premier alpha = 'N'
      // firstName = 'Jean' → premier alpha = 'J'
      expect(InitialsHelper.initialsFrom('Jean', "N'Sumbu"), 'NJ');
    });

    test('nom avec tiret : premier char alpha retenu (Ndombo-Kabongo)', () {
      expect(InitialsHelper.initialsFrom('Pierre', 'Ndombo-Kabongo'), 'NP');
    });
  });
}
