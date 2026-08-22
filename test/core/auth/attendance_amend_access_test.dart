import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';

/// La frontière entre **constater** et **arbitrer**, côté client.
///
/// Le serveur reste la seule frontière réelle — il refait le calcul sur sa
/// propre horloge et sur ses propres autorités. Mais cette écriture part par
/// l'outbox, où un 403 est classé TERMINAL : sans la garde, l'enseignant
/// corrigerait hors ligne, croirait avoir corrigé, et la saisie mourrait plus
/// tard sans rattrapage. Le masquage n'est donc pas cosmétique ici.
void main() {
  /// Ce que porte l'enseignant (miroir du gabarit serveur `TEACHER`).
  const enseignant = ['attendance.read', 'attendance.write'];

  /// Ce que porte la surveillance générale (`DISCIPLINE_SUPERVISOR`).
  const discipline = [
    'attendance.read',
    'attendance.write',
    'attendance.amend',
  ];

  group('kAttendanceAmendAccess — corriger un appel d\'un jour révolu', () {
    test(
      'l\'enseignant enregistre un appel mais ne corrige pas un jour révolu',
      () {
        expect(
          canAccess(
            requires: kAttendanceRecordAccess.requires,
            permissions: enseignant,
            requiresAll: kAttendanceRecordAccess.requiresAll,
          ),
          isTrue,
        );

        expect(
          canAccess(
            requires: kAttendanceAmendAccess.requires,
            permissions: enseignant,
            requiresAll: kAttendanceAmendAccess.requiresAll,
          ),
          isFalse,
        );
      },
    );

    test('la surveillance générale fait les deux', () {
      for (final access in [kAttendanceRecordAccess, kAttendanceAmendAccess]) {
        expect(
          canAccess(
            requires: access.requires,
            permissions: discipline,
            requiresAll: access.requiresAll,
          ),
          isTrue,
        );
      }
    });

    test('c\'est une CONJONCTION : amend seul ne suffit pas', () {
      // Le point d'entrée est le même que la prise d'appel ; arbitrer sans
      // pouvoir écrire n'a pas de sens, et une disjonction ouvrirait la
      // correction à qui ne détiendrait que le droit d'arbitrer.
      expect(kAttendanceAmendAccess.requiresAll, isTrue);
      expect(
        canAccess(
          requires: kAttendanceAmendAccess.requires,
          permissions: const ['attendance.amend'],
          requiresAll: true,
        ),
        isFalse,
      );
    });

    test('ensemble de permissions INCONNU : l\'interface se ferme', () {
      // `null` n'est pas « aucun droit » : c'est « on ne sait pas ». La
      // politique ferme, et c'est l'asymétrie assumée avec la synchronisation,
      // qui tire sur inconnu.
      expect(
        canAccess(
          requires: kAttendanceAmendAccess.requires,
          permissions: null,
          requiresAll: true,
        ),
        isFalse,
      );
    });

    test('l\'exigence est nommée dans le registre des actions gardées', () {
      // Sans quoi le test qui vérifie qu\'aucune exigence n\'est hors de portée
      // de tous les rôles ne la verrait jamais.
      expect(kGuardedWriteActions.values, contains(kAttendanceAmendAccess));
    });
  });
}
