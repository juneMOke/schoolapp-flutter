import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/load_expense_thread_use_case.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_queue_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_queue_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSource extends Mock implements ExpenseSnapshotSource {}

class _MockThread extends Mock implements LoadExpenseThreadUseCase {}

class _MockGesture extends Mock implements ApplyExpenseGestureUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// L'écran de la file, monté par sa coquille : ce qu'il montre, et à qui.
void main() {
  const type = ExpenseType(
    id: 't-elec',
    code: 'ELECTRICITE',
    label: 'Électricité & eau',
    shortLabel: 'Électricité',
    icon: 'power',
    colorHex: '#D9A24E',
    softColorHex: '#FBF3E3',
    defaultCurrency: 'CDF',
    sortOrder: 0,
    active: true,
  );

  const lecture = <String>['expense.read'];
  const direction = <String>[
    'expense.read',
    'expense.write',
    'expense.decide',
    'expense.pay',
    'expense.reopen',
  ];

  // Samedi 12 septembre 2026.
  final today = DateTime(2026, 9, 12);

  Expense expense(
    String id, {
    String title = 'Facture SNEL',
    ExpenseStatus status = ExpenseStatus.pending,
    String day = '2026-09-10',
    DateTime? decidedAt,
    String? decidedByName,
  }) => Expense(
    id: id,
    number: 'DEP-04$id',
    typeId: 't-elec',
    title: title,
    amountInCents: 2500,
    currency: 'USD',
    status: status,
    expenseDate: DateTime.parse(day),
    recordedByName: 'Moke Junior',
    recordedById: 'u-autre',
    decidedAt: decidedAt,
    decidedByName: decidedByName,
    clientUpdatedAt: DateTime.utc(2026),
  );

  Future<ExpenseQueueCubit> pump(
    WidgetTester tester, {
    required List<Expense> expenses,
    List<String> permissions = direction,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final source = _MockSource();
    when(() => source.watch(any())).thenReturn(() {});
    when(() => source.read()).thenAnswer(
      (_) async => Right(
        ExpenseRegisterSnapshot(types: const [type], expenses: expenses),
      ),
    );
    final cubit = ExpenseQueueCubit(
      source: source,
      gesture: _MockGesture(),
      thread: _MockThread(),
      now: () => today,
    );
    addTearDown(cubit.close);

    final auth = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(
      auth,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<ExpenseQueueCubit>.value(value: cubit),
            ],
            child: const ExpenseQueueScreen(),
          ),
        ),
      ),
    );
    await cubit.load();
    // Un cubit ne peint qu'à la seconde frame.
    await tester.pump();
    await tester.pump();
    return cubit;
  }

  testWidgets('la file s\'ouvre sur la demande qui attend depuis le plus '
      'longtemps', (tester) async {
    await pump(
      tester,
      expenses: [
        expense('1', title: 'Récente', day: '2026-09-11'),
        expense('2', title: 'Ancienne', day: '2026-09-02'),
      ],
    );

    final ancienne = tester.getTopLeft(find.text('Ancienne')).dy;
    final recente = tester.getTopLeft(find.text('Récente')).dy;
    expect(ancienne, lessThan(recente));
    // Dix jours d'attente : le palier chaud est franchi.
    expect(find.text('depuis 10 jours'), findsOneWidget);
    expect(find.text('depuis 1 jour'), findsOneWidget);
  });

  testWidgets('le vide de la file est une BONNE nouvelle : pas d\'anatomie '
      'd\'échec, pas de « Réessayer »', (tester) async {
    await pump(tester, expenses: [expense('1', status: ExpenseStatus.paid)]);

    expect(find.text('La file est vide'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('Ouvrir le registre'), findsOneWidget);
  });

  testWidgets('file vide mais dette vivante : le vide dit ce qui reste à '
      'payer', (tester) async {
    await pump(
      tester,
      expenses: [expense('1', status: ExpenseStatus.approved)],
    );

    expect(
      find.textContaining('1 dépense approuvée reste à payer'),
      findsOneWidget,
    );
  });

  group('les droits', () {
    testWidgets('sans expense.decide : ni case à cocher, ni Approuver — et '
        'l\'écran dit pourquoi', (tester) async {
      await pump(tester, expenses: [expense('1')], permissions: lecture);

      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Approuver'), findsNothing);
      expect(
        find.textContaining('Vous voyez la file mais ne décidez pas'),
        findsOneWidget,
      );
    });

    testWidgets('avec expense.decide : la case, les deux boutons, et pas de '
        'bandeau de repli', (tester) async {
      await pump(tester, expenses: [expense('1')]);

      // Une case par ligne, plus celle de l'en-tête.
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.text('Approuver'), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
      expect(
        find.textContaining('Vous voyez la file mais ne décidez pas'),
        findsNothing,
      );
    });
  });

  testWidgets('cocher une ligne ouvre la barre de lot ; la décocher la '
      'referme', (tester) async {
    final cubit = await pump(tester, expenses: [expense('1'), expense('2')]);

    expect(find.text('Approuver en lot'), findsNothing);

    cubit.toggleSelection('1');
    await tester.pump();
    await tester.pump();

    // La barre accole le compte et la somme : « 1 demande sélectionnée · … ».
    expect(find.textContaining('1 demande sélectionnée'), findsOneWidget);
    expect(find.text('Approuver en lot'), findsOneWidget);

    cubit.clearSelection();
    await tester.pump();
    await tester.pump();

    expect(find.text('Approuver en lot'), findsNothing);
  });

  testWidgets('refuser en lot exige un motif commun avant de partir', (
    tester,
  ) async {
    final cubit = await pump(tester, expenses: [expense('1')]);
    cubit.toggleSelection('1');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Refuser en lot'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Motif du refus — 1 demande'), findsOneWidget);
    await tester.tap(find.text('Confirmer le refus'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Un refus sans motif laisse le demandeur sans issue.'),
      findsOneWidget,
    );
  });

  group('approuvées, à payer', () {
    testWidgets('la carte nomme le décideur et offre de constater le '
        'paiement', (tester) async {
      await pump(
        tester,
        expenses: [
          expense(
            '1',
            status: ExpenseStatus.approved,
            decidedAt: DateTime.utc(2026, 9, 9, 10),
            decidedByName: 'Mbala Thérèse',
          ),
        ],
      );

      expect(find.text('Approuvées, en attente de paiement'), findsOneWidget);
      expect(find.textContaining('Mbala Thérèse'), findsOneWidget);
      expect(find.text('Marquer payée'), findsOneWidget);
    });

    testWidgets('décideur inconnu : la carte le DIT, elle n\'invente pas un '
        'nom', (tester) async {
      await pump(
        tester,
        expenses: [expense('1', status: ExpenseStatus.approved)],
      );

      expect(
        find.textContaining('décideur non encore connu de ce poste'),
        findsOneWidget,
      );
    });

    testWidgets('sans expense.pay : la ligne reste consultable', (
      tester,
    ) async {
      await pump(
        tester,
        expenses: [expense('1', status: ExpenseStatus.approved)],
        permissions: lecture,
      );

      expect(find.text('Marquer payée'), findsNothing);
      expect(find.text('Ouvrir la demande'), findsOneWidget);
    });
  });
}
