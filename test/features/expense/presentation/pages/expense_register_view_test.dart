import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_period_memory.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_register_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSource extends Mock implements ExpenseSnapshotSource {}

class _MockSave extends Mock implements SaveExpenseUseCase {}

class _MockSetStatus extends Mock implements SetExpenseStatusUseCase {}

class _MockWithdraw extends Mock implements WithdrawExpenseUseCase {}

class _MockRestore extends Mock implements RestoreExpenseUseCase {}

const _types = [
  ExpenseType(
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
  ),
  ExpenseType(
    id: 't-four',
    code: 'FOURNITURES',
    label: 'Fournitures (scolaires & bureau)',
    shortLabel: 'Fournitures',
    icon: 'book-marked',
    colorHex: '#1B4D6B',
    softColorHex: '#EBF2F7',
    defaultCurrency: 'USD',
    sortOrder: 1,
    active: true,
  ),
];

Expense _expense(
  String id, {
  required String title,
  required String day,
  String typeId = 't-elec',
  String? number,
  int cents = 38500000,
  String currency = 'CDF',
}) => Expense(
  id: id,
  number: number,
  typeId: typeId,
  title: title,
  amountInCents: cents,
  currency: currency,
  status: ExpenseStatus.paid,
  expenseDate: DateTime.parse(day),
  clientUpdatedAt: DateTime.utc(2026, 9, 1),
  syncState: number == null
      ? ExpenseSyncState.pending
      : ExpenseSyncState.synced,
);

/// L'état émis par le cubit arrive au BlocBuilder APRÈS la frame en cours :
/// il en faut une seconde pour le voir peint (mesuré : 2 lignes à la première
/// frame, 1 à la suivante).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late _MockSource source;

  setUp(() {
    source = _MockSource();
    when(() => source.watch(any())).thenReturn(() {});
  });

  Future<ExpenseRegisterCubit> pumpRegister(
    WidgetTester tester, {
    required Either<Failure, ExpenseRegisterSnapshot> read,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => source.read()).thenAnswer((_) async => read);
    final cubit = ExpenseRegisterCubit(
      source: source,
      memory: ExpensePeriodMemory(),
      save: _MockSave(),
      setStatus: _MockSetStatus(),
      withdraw: _MockWithdraw(),
      restore: _MockRestore(),
      now: () => DateTime(2026, 9, 12),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<ExpenseRegisterCubit>.value(
            value: cubit,
            child: const ExpenseRegisterView(),
          ),
        ),
      ),
    );
    await cubit.load();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return cubit;
  }

  final septembre = ExpenseRegisterSnapshot(
    types: _types,
    expenses: [
      _expense(
        'a',
        title: 'Facture SNEL',
        day: '2026-09-03',
        number: 'DEP-0412',
      ),
      _expense(
        'b',
        title: 'Ramettes de papier',
        day: '2026-09-03',
        typeId: 't-four',
        cents: 14200,
        currency: 'USD',
      ),
    ],
  );

  testWidgets('le registre nomme ses lignes ; une saisie non accusée dit son '
      'numéro « en attente » (A3)', (tester) async {
    await pumpRegister(tester, read: Right(septembre));

    expect(find.text('Facture SNEL'), findsOneWidget);
    expect(find.text('Ramettes de papier'), findsOneWidget);
    expect(find.textContaining('DEP-0412'), findsOneWidget);
    expect(find.text('N° en attente'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recherche sans résultat → vide « recherche » ; réinitialiser '
      'rend le registre', (tester) async {
    final cubit = await pumpRegister(tester, read: Right(septembre));

    cubit.setText('introuvable');
    await _settle(tester);
    expect(find.text('Aucune dépense ne correspond'), findsOneWidget);

    await tester.tap(find.text('Réinitialiser les filtres'));
    await _settle(tester);
    expect(find.text('Facture SNEL'), findsOneWidget);
  });

  testWidgets('recherche insensible aux accents (A7)', (tester) async {
    final cubit = await pumpRegister(tester, read: Right(septembre));

    cubit.setText('electricite');
    await _settle(tester);
    expect(find.text('Facture SNEL'), findsOneWidget);
    expect(find.text('Ramettes de papier'), findsNothing);
  });

  testWidgets('période sans dépense → vide « période » ; « Voir le mois '
      'entier » ne s’offre que sous le mois', (tester) async {
    final cubit = await pumpRegister(
      tester,
      read: const Right(ExpenseRegisterSnapshot(types: _types, expenses: [])),
    );

    expect(find.text('Aucune dépense sur ce mois-ci'), findsOneWidget);
    expect(find.text('Nouvelle dépense'), findsWidgets);
    expect(find.text('Voir le mois entier'), findsNothing);

    cubit.setGranularity(ExpenseGranularity.week);
    await _settle(tester);
    expect(find.text('Voir le mois entier'), findsOneWidget);
  });

  testWidgets('un filtre sur une période sans dépense : le vide dit la '
      'période, pas la recherche', (tester) async {
    final cubit = await pumpRegister(
      tester,
      read: const Right(ExpenseRegisterSnapshot(types: _types, expenses: [])),
    );

    cubit.setText('snel');
    await _settle(tester);

    expect(find.text('Aucune dépense sur ce mois-ci'), findsOneWidget);
    expect(find.text('Aucune dépense ne correspond'), findsNothing);
  });

  testWidgets('registre illisible → l’état d’erreur partagé, avec Réessayer', (
    tester,
  ) async {
    await pumpRegister(
      tester,
      read: const Left(StorageFailure('base verrouillée')),
    );

    expect(find.text('Registre illisible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
