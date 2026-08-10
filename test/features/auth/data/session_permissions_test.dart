import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/data/session_permissions.dart';

void main() {
  group('SessionPermissions.sanitize', () {
    test('conserve l\'ordre serveur et les valeurs inconnues', () {
      expect(
        SessionPermissions.sanitize(<String>[
          'attendance.read',
          'module.futur.write',
        ]),
        <String>['attendance.read', 'module.futur.write'],
      );
    });

    test('écarte entrées non-chaînes, vides et doublons', () {
      expect(
        SessionPermissions.sanitize(<dynamic>[
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

    test('valeur non-liste → ensemble vide (fail-closed)', () {
      expect(SessionPermissions.sanitize(null), isEmpty);
      expect(SessionPermissions.sanitize('a.read'), isEmpty);
      expect(SessionPermissions.sanitize(42), isEmpty);
      expect(SessionPermissions.sanitize(<String, dynamic>{}), isEmpty);
    });
  });

  group('SessionPermissions encode/decode', () {
    test('aller-retour fidèle', () {
      const permissions = <String>['attendance.read', 'academics.grade.write'];
      expect(
        SessionPermissions.decode(SessionPermissions.encode(permissions)),
        permissions,
      );
    });

    test('aller-retour d\'un ensemble vide', () {
      expect(
        SessionPermissions.decode(SessionPermissions.encode(const [])),
        isEmpty,
      );
    });

    test('valeurs porteuses de séparateurs : le JSON les préserve', () {
      // L'ensemble est ouvert : aucun séparateur ne peut être garanti absent
      // d'une valeur future, d'où le JSON plutôt qu'une chaîne jointe.
      const permissions = <String>['a,b.read', 'c;d.write', 'e f.read'];
      expect(
        SessionPermissions.decode(SessionPermissions.encode(permissions)),
        permissions,
      );
    });

    test('stockage absent ou vide → ensemble vide', () {
      expect(SessionPermissions.decode(null), isEmpty);
      expect(SessionPermissions.decode(''), isEmpty);
    });

    test('stockage corrompu → ensemble vide, jamais d\'exception', () {
      expect(SessionPermissions.decode('{pas du json'), isEmpty);
      expect(SessionPermissions.decode('"une chaîne"'), isEmpty);
      expect(SessionPermissions.decode('{"a":1}'), isEmpty);
    });
  });
}
