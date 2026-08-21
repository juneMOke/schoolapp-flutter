import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// `permissionHolding` sert à **expliquer** un écran vide, pas à autoriser :
/// c'est pourquoi il rend trois états là où `canAccess` en rend deux.
///
/// La différence porte entièrement sur [PermissionHolding.unknown] : `canAccess`
/// répond `false` sur un ensemble jamais communiqué — fail-closed délibéré —
/// alors qu'ici il faut se taire. Un parc de sessions ouvertes avant la
/// migration qui a introduit les permissions est entièrement en `null`, ces
/// comptes ont tous les droits, et leur dire « votre profil n'a pas accès »
/// remplacerait un message faux par un message pire.
void main() {
  /// Rend le contexte d'un arbre monté avec — ou sans — `AuthBloc`.
  ///
  /// [mountAuth] à `false` reproduit le harnais qui monte une page métier
  /// seule : le cas est distinct de `permissions: null`, et les deux doivent
  /// répondre la même chose.
  Future<BuildContext> pump(
    WidgetTester tester, {
    required List<String>? permissions,
    bool mountAuth = true,
  }) async {
    late BuildContext captured;
    final probe = Builder(
      builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      },
    );

    Widget child = probe;
    if (mountAuth) {
      final authBloc = _MockAuthBloc();
      final state = AuthState(
        status: AuthStatus.authenticated,
        permissions: permissions,
      );
      when(() => authBloc.state).thenReturn(state);
      whenListen(authBloc, Stream<AuthState>.value(state), initialState: state);
      child = BlocProvider<AuthBloc>.value(value: authBloc, child: probe);
    }

    await tester.pumpWidget(MaterialApp(home: child));
    return captured;
  }

  testWidgets('permission détenue → granted', (tester) async {
    final context = await pump(
      tester,
      permissions: const ['enrollment.read', 'finance.charge.read'],
    );

    expect(
      permissionHolding(context, const [Perm.enrollmentRead]),
      PermissionHolding.granted,
    );
  });

  testWidgets('ensemble connu mais sans l\'exigence → missing', (tester) async {
    final context = await pump(
      tester,
      permissions: const ['finance.charge.read'],
    );

    expect(
      permissionHolding(context, const [Perm.enrollmentRead]),
      PermissionHolding.missing,
    );
  });

  testWidgets('ensemble connu et vide → missing, pas unknown', (tester) async {
    final context = await pump(tester, permissions: const <String>[]);

    expect(
      permissionHolding(context, const [Perm.enrollmentRead]),
      PermissionHolding.missing,
      reason:
          'une liste vide est un ensemble communiqué : on sait qu\'il ne '
          'contient rien',
    );
  });

  // Le parc entier est dans cet état au premier démarrage post-migration.
  testWidgets('ensemble jamais communiqué (null) → unknown', (tester) async {
    final context = await pump(tester, permissions: null);

    expect(
      permissionHolding(context, const [Perm.enrollmentRead]),
      PermissionHolding.unknown,
    );
  });

  // Sans bloc, `PermissionGate` laisse passer — ici cela ne vaut surtout pas
  // `granted` : on n'a lu aucun droit, on ne peut donc en affirmer aucun.
  testWidgets('sans AuthBloc dans l\'arbre → unknown, jamais granted', (
    tester,
  ) async {
    final context = await pump(tester, permissions: null, mountAuth: false);

    final holding = permissionHolding(context, const [Perm.enrollmentRead]);
    expect(holding, PermissionHolding.unknown);
    expect(holding, isNot(PermissionHolding.granted));
  });

  group('conjonction', () {
    testWidgets('les deux détenues → granted', (tester) async {
      final context = await pump(
        tester,
        permissions: const ['finance.payment.write', 'editique.write'],
      );

      expect(
        permissionHolding(context, const [
          Perm.financePaymentWrite,
          Perm.editiqueWrite,
        ], requiresAll: true),
        PermissionHolding.granted,
      );
    });

    testWidgets('une seule des deux → missing', (tester) async {
      final context = await pump(
        tester,
        permissions: const ['finance.payment.write'],
      );

      expect(
        permissionHolding(context, const [
          Perm.financePaymentWrite,
          Perm.editiqueWrite,
        ], requiresAll: true),
        PermissionHolding.missing,
      );
      // Sans conjonction, la même session satisfait l'exigence.
      expect(
        permissionHolding(context, const [
          Perm.financePaymentWrite,
          Perm.editiqueWrite,
        ]),
        PermissionHolding.granted,
      );
    });
  });

  group('exigence vide (déclaration oubliée)', () {
    // `canAccess` est fail-closed sur `requires` vide — juste pour une garde,
    // qui protège. Ce helper, lui, ne fait qu'EXPLIQUER un vide : accuser le
    // profil sur la foi d'une déclaration oubliée serait pire que se taire.
    // Il ne rend donc JAMAIS `missing` sans exigence à confronter.
    testWidgets('sur ensemble connu → unknown, jamais missing', (tester) async {
      final context = await pump(
        tester,
        permissions: const ['enrollment.read'],
      );

      expect(
        permissionHolding(context, const <Perm>[]),
        PermissionHolding.unknown,
      );
    });

    // L'inconnu prime : on ne sait toujours rien de la session.
    testWidgets('sur ensemble inconnu → unknown', (tester) async {
      final context = await pump(tester, permissions: null);

      expect(
        permissionHolding(context, const <Perm>[]),
        PermissionHolding.unknown,
      );
    });
  });
}
