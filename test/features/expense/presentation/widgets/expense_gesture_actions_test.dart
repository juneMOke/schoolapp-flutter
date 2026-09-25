import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_gesture_access.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Le **câblage** des trois filtres de F29 — permission × état × propriété —
/// et pas seulement chacun pris à part.
///
/// La politique seule est épinglée dans `expense_gesture_policy_test.dart`.
/// Ce fichier-ci répond à l'autre moitié : une garde peut être écrite, testée,
/// et jamais branchée. Un bouton offert sans son droit fabrique une entrée
/// d'outbox morte — 403 comme 422 sont terminaux — et une ligne « à corriger »
/// que son auteur ne peut pas corriger.
void main() {
  const moi = 'u-moi';
  const collegue = 'u-collegue';

  const lecture = <String>['expense.read'];
  const economat = <String>['expense.read', 'expense.write'];
  const direction = <String>[
    'expense.read',
    'expense.write',
    'expense.decide',
    'expense.pay',
    'expense.reopen',
  ];

  Expense expense({
    ExpenseStatus status = ExpenseStatus.pending,
    String recordedById = collegue,
  }) => Expense(
    id: 'e-1',
    typeId: 't-elec',
    title: 'Facture SNEL',
    amountInCents: 38500000,
    currency: 'CDF',
    status: status,
    expenseDate: DateTime(2026, 9, 3),
    recordedById: recordedById,
    clientUpdatedAt: DateTime.utc(2026, 9, 3),
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<String> permissions,
    required Expense on,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, Stream<AuthState>.value(state), initialState: state);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: auth,
            child: ExpenseDetailActions(
              expense: on,
              accountId: moi,
              onShortcut: (_) {},
              onGesture: (_) {},
              onRefuse: () {},
            ),
          ),
        ),
      ),
    );
    // Un cubit ne peint qu'à la seconde frame.
    await tester.pump();
  }

  group('le droit', () {
    testWidgets('sans expense.decide, la demande d\'un collègue n\'offre '
        'aucune décision', (tester) async {
      await pump(tester, permissions: economat, on: expense());

      expect(find.text('Approuver'), findsNothing);
      expect(find.text('Refuser'), findsNothing);
    });

    testWidgets('avec expense.decide, les deux boutons sont là', (
      tester,
    ) async {
      await pump(tester, permissions: direction, on: expense());

      expect(find.text('Approuver'), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
    });

    testWidgets('payer et annuler la décision ont chacun LEUR droit', (
      tester,
    ) async {
      await pump(
        tester,
        permissions: economat,
        on: expense(status: ExpenseStatus.approved),
      );
      expect(find.text('Marquer payée'), findsNothing);
      expect(find.text('Annuler la décision'), findsNothing);

      await pump(
        tester,
        permissions: direction,
        on: expense(status: ExpenseStatus.approved),
      );
      expect(find.text('Marquer payée'), findsOneWidget);
      expect(find.text('Annuler la décision'), findsOneWidget);
    });

    testWidgets('en lecture seule, le pied ne propose RIEN', (tester) async {
      await pump(tester, permissions: lecture, on: expense());

      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Dupliquer'), findsNothing);
      expect(find.text('Approuver'), findsNothing);
    });
  });

  group('la propriété', () {
    testWidgets('sur SA PROPRE demande, la direction décide aussi', (
      tester,
    ) async {
      // A11 abandonnée le 2026-09-25 : un directeur tranche ses propres
      // demandes, personne d'autre ne le pourrait.
      await pump(
        tester,
        permissions: direction,
        on: expense(recordedById: moi),
      );

      expect(find.text('Approuver'), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
      // Et ce qui revient au demandeur reste offert.
      expect(find.text('Retirer'), findsOneWidget);
      expect(find.text('Relancer'), findsOneWidget);
    });

    testWidgets('la demande d\'un collègue ne se relance ni ne se retire', (
      tester,
    ) async {
      await pump(tester, permissions: direction, on: expense());

      expect(find.text('Retirer'), findsNothing);
      expect(find.text('Relancer'), findsNothing);
    });

    testWidgets('corriger et renvoyer n\'est offert qu\'au demandeur, et sur '
        'une demande refusée ou retirée', (tester) async {
      await pump(
        tester,
        permissions: economat,
        on: expense(status: ExpenseStatus.refused, recordedById: moi),
      );
      expect(find.text('Corriger et renvoyer'), findsOneWidget);

      await pump(
        tester,
        permissions: economat,
        on: expense(status: ExpenseStatus.refused),
      );
      expect(find.text('Corriger et renvoyer'), findsNothing);
    });
  });

  group('Modifier', () {
    testWidgets('tant que personne n\'a décidé, et sur sa propre demande', (
      tester,
    ) async {
      await pump(
        tester,
        permissions: economat,
        on: expense(recordedById: moi),
      );

      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('une demande ACCORDÉE ne se réécrit plus : elle ne serait '
        'plus celle qui a été accordée', (tester) async {
      await pump(
        tester,
        permissions: direction,
        on: expense(status: ExpenseStatus.approved, recordedById: moi),
      );

      expect(find.text('Modifier'), findsNothing);
      // Dupliquer reste : repartir d'une ligne n'en réécrit aucune.
      expect(find.text('Dupliquer'), findsOneWidget);
    });

    testWidgets('la demande d\'un collègue ne se modifie pas', (tester) async {
      await pump(tester, permissions: direction, on: expense());

      expect(find.text('Modifier'), findsNothing);
    });
  });

  testWidgets('Refuser ne part PAS tout seul : il ouvre le panneau de motif', (
    tester,
  ) async {
    ExpenseGesture? fired;
    var asked = 0;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _MockAuthBloc();
    const state = AuthState(
      status: AuthStatus.authenticated,
      permissions: direction,
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, Stream<AuthState>.value(state), initialState: state);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: auth,
            child: ExpenseDetailActions(
              expense: expense(),
              accountId: moi,
              onShortcut: (_) {},
              onGesture: (gesture) => fired = gesture,
              onRefuse: () => asked++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Ligne de contrôle : Approuver, lui, part directement.
    await tester.tap(find.text('Approuver'));
    await tester.pump();
    expect(fired, ExpenseGesture.approve);

    await tester.tap(find.text('Refuser'));
    await tester.pump();

    expect(asked, 1);
    // Un refus sans motif n'existe pas : le geste n'est pas parti.
    expect(fired, ExpenseGesture.approve);
  });

  test('chaque geste du pied a son ModuleAccess, et aucun n\'est oublié', () {
    // Le `switch` est exhaustif à la compilation ; ce test dit l'autre moitié :
    // tout geste offrable ailleurs qu'au fil passe bien par une garde.
    for (final gesture in ExpenseGesture.values) {
      expect(
        expenseGestureAccess(gesture).requires,
        isNotEmpty,
        reason: gesture.name,
      );
    }
  });
}
