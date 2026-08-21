import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/data/session_permissions.dart';

/// Le codec porte une distinction à trois états, et c'est elle qui compte :
/// replier « je ne sais pas » sur « rien » transforme une montée de version en
/// retrait total de droits pour tout le parc, et coupe du même coup la boucle
/// de synchronisation qui seule pourrait réparer l'état.
void main() {
  group('sanitizeOrNull (valeur venue du fil)', () {
    test('conserve l\'ordre serveur et les valeurs inconnues', () {
      expect(
        SessionPermissions.sanitizeOrNull(<String>[
          'attendance.read',
          'module.futur.write',
        ]),
        <String>['attendance.read', 'module.futur.write'],
      );
    });

    test('écarte entrées non-chaînes, vides et doublons', () {
      expect(
        SessionPermissions.sanitizeOrNull(<dynamic>[
          'a.read',
          '  a.write  ',
          'a.read',
          '',
          '   ',
          7,
          null,
          <String>['imbriqué'],
        ]),
        <String>['a.read', 'a.write'],
      );
    });

    test('liste vide → ensemble vide : le serveur a parlé', () {
      expect(SessionPermissions.sanitizeOrNull(<dynamic>[]), isEmpty);
    });

    // Le champ absent ne dit RIEN. L'écraser en « aucun droit » dépouillerait
    // l'agent au premier contact d'un backend qui ignore encore ADR-014.
    test('champ absent ou null → inconnu', () {
      expect(SessionPermissions.sanitizeOrNull(null), isNull);
    });

    test('type inattendu → inconnu, jamais un ensemble vide', () {
      expect(SessionPermissions.sanitizeOrNull('a.read'), isNull);
      expect(SessionPermissions.sanitizeOrNull(42), isNull);
      expect(SessionPermissions.sanitizeOrNull(<String, dynamic>{}), isNull);
    });
  });

  group('encode / decodeOrNull (valeur stockée)', () {
    test('aller-retour fidèle', () {
      const permissions = <String>['attendance.read', 'academics.grade.write'];
      expect(
        SessionPermissions.decodeOrNull(SessionPermissions.encode(permissions)),
        permissions,
      );
    });

    // Le pivot du dispositif : l'ensemble vide s'écrit `[]` et se relit vide,
    // donc « le serveur a retiré tous les droits » survit au redémarrage.
    test('l\'ensemble vide fait un aller-retour SANS devenir inconnu', () {
      final encode = SessionPermissions.encode(const <String>[]);
      expect(encode, '[]');
      expect(SessionPermissions.decodeOrNull(encode), isEmpty);
      expect(SessionPermissions.decodeOrNull(encode), isNotNull);
    });

    test('valeurs porteuses de séparateurs : le JSON les préserve', () {
      // L'ensemble est ouvert : aucun séparateur ne peut être garanti absent
      // d'une valeur future, d'où le JSON plutôt qu'une chaîne jointe.
      const permissions = <String>['a,b.read', 'c;d.write', 'e f.read'];
      expect(
        SessionPermissions.decodeOrNull(SessionPermissions.encode(permissions)),
        permissions,
      );
    });

    // Rien d'enregistré : c'est exactement le cas d'un compte connu avant la
    // migration v24 (colonne ajoutée sans backfill, clé de storage absente).
    test('stockage absent ou vide → inconnu', () {
      expect(SessionPermissions.decodeOrNull(null), isNull);
      expect(SessionPermissions.decodeOrNull(''), isNull);
    });

    test('stockage corrompu → inconnu, jamais d\'exception', () {
      // Une donnée illisible ne prouve pas un retrait de droits.
      expect(SessionPermissions.decodeOrNull('{pas du json'), isNull);
      expect(SessionPermissions.decodeOrNull('"une chaîne"'), isNull);
      expect(SessionPermissions.decodeOrNull('{"a":1}'), isNull);
    });
  });
}
