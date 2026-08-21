import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';

void main() {
  group('canAccess — disjonction (défaut)', () {
    test('une seule exigence détenue → accès', () {
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead],
          permissions: const ['enrollment.read', 'student.read'],
        ),
        isTrue,
      );
    });

    test('aucune des exigences détenue → refus', () {
      expect(
        canAccess(
          requires: const [Perm.financeChargeRead, Perm.financePaymentRead],
          permissions: const ['enrollment.read'],
        ),
        isFalse,
      );
    });

    test('l\'une des deux suffit', () {
      expect(
        canAccess(
          requires: const [Perm.attendanceRead, Perm.disciplineRead],
          permissions: const ['discipline.read'],
        ),
        isTrue,
      );
    });
  });

  group('canAccess — conjonction', () {
    // Le cas type est l'encaissement hors ligne : il encaisse ET scelle le
    // reçu. Gardé sur la seule permission de caisse, il laisserait produire une
    // pièce numérotée qu'on n'a pas le droit de produire (ADR-014 §2.11).
    const paiementOffline = [Perm.financePaymentWrite, Perm.editiqueWrite];

    test('les deux détenues → accès', () {
      expect(
        canAccess(
          requires: paiementOffline,
          permissions: const ['finance.payment.write', 'editique.write'],
          requiresAll: true,
        ),
        isTrue,
      );
    });

    test('une seule détenue → refus', () {
      expect(
        canAccess(
          requires: paiementOffline,
          permissions: const ['finance.payment.write'],
          requiresAll: true,
        ),
        isFalse,
      );
    });

    test(
      'la même exigence en disjonction aurait ouvert — d\'où le drapeau',
      () {
        expect(
          canAccess(
            requires: paiementOffline,
            permissions: const ['finance.payment.write'],
          ),
          isTrue,
        );
      },
    );
  });

  group('fail-closed', () {
    // Unique point de fermeture du tri-état côté interface, et le plus exposé :
    // à la montée v24, TOUT le parc est dans cet état — colonne ajoutée sans
    // backfill, clé de storage absente. Une régression sur cette ligne frappe
    // 100 % des postes le jour même. Le pendant côté synchro (null = on tire)
    // est épinglé deux fois dans `pull_coordinator_test.dart` ; celui-ci ne
    // l'était pas du tout.
    test('ensemble INCONNU (null) → refus, comme le vide', () {
      expect(
        canAccess(requires: const [Perm.enrollmentRead], permissions: null),
        isFalse,
      );
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead, Perm.editiqueWrite],
          permissions: null,
          requiresAll: true,
        ),
        isFalse,
      );
    });

    test('ensemble effectif vide → refus', () {
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead],
          permissions: const <String>[],
        ),
        isFalse,
      );
    });

    test('ensemble effectif vide → refus aussi en conjonction', () {
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead, Perm.editiqueWrite],
          permissions: const <String>[],
          requiresAll: true,
        ),
        isFalse,
      );
    });

    // `every` sur une liste vide rend `true` : sans la garde explicite, une
    // exigence oubliée dans le registre ouvrirait le module en conjonction et
    // le fermerait en disjonction. Un oubli doit refuser, dans les deux modes.
    test(
      'exigence vide → refus (et non l\'ouverture que `every` donnerait)',
      () {
        expect(
          canAccess(requires: const [], permissions: const ['enrollment.read']),
          isFalse,
        );
        expect(
          canAccess(
            requires: const [],
            permissions: const ['enrollment.read'],
            requiresAll: true,
          ),
          isFalse,
        );
      },
    );
  });

  group('ensemble ouvert', () {
    test('une permission inconnue du client est sans effet', () {
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead],
          permissions: const ['module.futur.read', 'portail.web.access'],
        ),
        isFalse,
      );
    });

    test(
      'elle ne perturbe pas les permissions connues qui l\'accompagnent',
      () {
        expect(
          canAccess(
            requires: const [Perm.enrollmentRead],
            permissions: const ['module.futur.read', 'enrollment.read'],
          ),
          isTrue,
        );
      },
    );

    test('comparaison stricte : ni préfixe, ni casse, ni espace tolérés', () {
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead],
          permissions: const ['enrollment'],
        ),
        isFalse,
      );
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead],
          permissions: const ['ENROLLMENT.READ'],
        ),
        isFalse,
      );
      // `enrollment.write` n'implique pas `enrollment.read` : le résolveur est
      // bête par décision (ADR-014 §9), la définition de rôle liste les deux.
      expect(
        canAccess(
          requires: const [Perm.enrollmentRead],
          permissions: const ['enrollment.write'],
        ),
        isFalse,
      );
    });
  });

  test('fonction pure : ne modifie pas ses entrées', () {
    final permissions = <String>['enrollment.read'];
    final requires = <Perm>[Perm.enrollmentRead];

    canAccess(requires: requires, permissions: permissions);

    expect(permissions, ['enrollment.read']);
    expect(requires, [Perm.enrollmentRead]);
  });
}
