import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;

  Widget harness(Widget child, {required List<String>? permissions}) {
    authBloc = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => authBloc.state).thenReturn(state);
    whenListen(authBloc, Stream<AuthState>.value(state), initialState: state);
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(value: authBloc, child: child),
    );
  }

  const cta = Text('Encaisser');

  testWidgets('permission détenue → l\'action est offerte', (tester) async {
    await tester.pumpWidget(
      harness(
        const PermissionGate(requires: [Perm.financePaymentWrite], child: cta),
        permissions: const ['finance.payment.write'],
      ),
    );

    expect(find.text('Encaisser'), findsOneWidget);
  });

  // Le gate MASQUE là où `SessionWriteGate` GÈLE : un CTA estompé dit « pas
  // maintenant », un CTA absent dit « pas vous ».
  testWidgets('permission absente → rien, pas même un bouton inerte', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const PermissionGate(requires: [Perm.financePaymentWrite], child: cta),
        permissions: const ['finance.charge.read'],
      ),
    );

    expect(find.text('Encaisser'), findsNothing);
  });

  // Le parc entier est dans cet état au premier démarrage post-v24 : un CTA
  // d'écriture ne doit pas être offert sur des droits qu'on ignore.
  testWidgets('ensemble inconnu (null) → action masquée', (tester) async {
    await tester.pumpWidget(
      harness(
        const PermissionGate(requires: [Perm.financePaymentWrite], child: cta),
        permissions: null,
      ),
    );

    expect(find.text('Encaisser'), findsNothing);
  });

  testWidgets('conjonction : une seule des deux ne suffit pas', (tester) async {
    await tester.pumpWidget(
      harness(
        const PermissionGate(
          requires: [Perm.financePaymentWrite, Perm.editiqueWrite],
          requiresAll: true,
          child: cta,
        ),
        permissions: const ['finance.payment.write'],
      ),
    );

    expect(find.text('Encaisser'), findsNothing);
  });

  testWidgets('fallback affiché à la place quand il est fourni', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const PermissionGate(
          requires: [Perm.financePaymentWrite],
          fallback: Text('Lecture seule'),
          child: cta,
        ),
        permissions: const <String>[],
      ),
    );

    expect(find.text('Encaisser'), findsNothing);
    expect(find.text('Lecture seule'), findsOneWidget);
  });

  // Un droit retiré en cours de session (refresh) doit faire disparaître le CTA
  // sans que rien d'impératif ne l'ordonne (ADR-014 §5).
  testWidgets('un changement de droits recompose le gate', (tester) async {
    final bloc = _MockAuthBloc();
    const avant = AuthState(
      status: AuthStatus.authenticated,
      permissions: ['finance.payment.write'],
    );
    const apres = AuthState(
      status: AuthStatus.authenticated,
      permissions: <String>[],
    );
    whenListen(bloc, Stream<AuthState>.value(apres), initialState: avant);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const PermissionGate(
            requires: [Perm.financePaymentWrite],
            child: cta,
          ),
        ),
      ),
    );
    expect(find.text('Encaisser'), findsOneWidget);

    await tester.pump();
    expect(find.text('Encaisser'), findsNothing);
  });

  // Convention partagée avec `SessionWriteGate` : en production la racine
  // fournit toujours l'AuthBloc ; l'absence n'existe que dans les harnais qui
  // montent une page métier seule, et le gate y est transparent.
  testWidgets('sans AuthBloc dans l\'arbre : transparent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PermissionGate(requires: [Perm.financePaymentWrite], child: cta),
      ),
    );

    expect(find.text('Encaisser'), findsOneWidget);
  });

  group('allows (garde impérative)', () {
    testWidgets('rend le verdict de la session', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
          permissions: const ['enrollment.write'],
        ),
      );

      expect(PermissionGate.allows(ctx, const [Perm.enrollmentWrite]), isTrue);
      expect(PermissionGate.allows(ctx, const [Perm.editiqueWrite]), isFalse);
      expect(
        PermissionGate.allows(ctx, const [
          Perm.enrollmentWrite,
          Perm.editiqueWrite,
        ], requiresAll: true),
        isFalse,
      );
    });

    testWidgets('sans AuthBloc : autorise, comme le rendu', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(PermissionGate.allows(ctx, const [Perm.enrollmentWrite]), isTrue);
    });
  });
}
