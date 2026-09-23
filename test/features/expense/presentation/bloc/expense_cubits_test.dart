import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/load_expense_thread_use_case.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_dashboard_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_period_memory.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';

class _MockSource extends Mock implements ExpenseSnapshotSource {}

class _MockSave extends Mock implements SaveExpenseUseCase {}

class _MockWithdraw extends Mock implements WithdrawExpenseUseCase {}

class _MockRestore extends Mock implements RestoreExpenseUseCase {}

class _MockThread extends Mock implements LoadExpenseThreadUseCase {}

final _today = DateTime(2026, 9, 12);

Expense _expense(String id, {String day = '2026-09-03'}) => Expense(
  id: id,
  typeId: 't',
  title: 'Dépense $id',
  amountInCents: 1000,
  currency: 'USD',
  status: ExpenseStatus.paid,
  expenseDate: DateTime.parse(day),
  clientUpdatedAt: DateTime.utc(2026),
);

ExpenseRegisterSnapshot _snapshot(List<Expense> rows) =>
    ExpenseRegisterSnapshot(types: const [], expenses: rows);

void main() {
  late _MockSource source;
  late ExpensePeriodMemory memory;
  late _MockSave save;
  late void Function() changed;
  var unwatched = 0;

  setUpAll(() {
    registerFallbackValue(
      ExpenseDraft(
        typeId: 't',
        title: 'x',
        amountInCents: 1,
        currency: 'USD',
        expenseDate: DateTime(2026),
      ),
    );
  });

  setUp(() {
    source = _MockSource();
    memory = ExpensePeriodMemory();
    save = _MockSave();
    unwatched = 0;
    when(() => source.watch(any())).thenAnswer((invocation) {
      changed = invocation.positionalArguments.first as void Function();
      return () => unwatched++;
    });
  });

  ExpenseRegisterCubit register() => ExpenseRegisterCubit(
    source: source,
    memory: memory,
    save: save,
    withdraw: _MockWithdraw(),
    restore: _MockRestore(),
    thread: _MockThread(),
    now: () => _today,
  );

  group('ExpenseRegisterCubit', () {
    test('charge, puis relit EN SILENCE sur un signal de synchro', () async {
      when(
        () => source.read(),
      ).thenAnswer((_) async => Right(_snapshot([_expense('a')])));
      final cubit = register();
      await cubit.load();
      expect(cubit.state.status, ExpenseLoadStatus.ready);
      expect(cubit.state.view.rows, hasLength(1));

      // Une relecture de confort qui échoue ne remplace jamais les données.
      when(
        () => source.read(),
      ).thenAnswer((_) async => const Left(StorageFailure('base verrouillée')));
      changed();
      await pumpEventQueue();
      expect(cubit.state.status, ExpenseLoadStatus.ready);
      expect(cubit.state.view.rows, hasLength(1));

      await cubit.close();
      expect(unwatched, 1, reason: 'la fermeture désabonne');
    });

    test('un échec au chargement est un état d’erreur, pas un vide', () async {
      when(
        () => source.read(),
      ).thenAnswer((_) async => const Left(StorageFailure('illisible')));
      final cubit = register();
      await cubit.load();
      expect(cubit.state.status, ExpenseLoadStatus.failure);
      await cubit.close();
    });

    test('changer de période ou de filtre remet le palier à 40', () async {
      when(
        () => source.read(),
      ).thenAnswer((_) async => Right(_snapshot([_expense('a')])));
      final cubit = register();
      await cubit.load();
      cubit.showMore();
      expect(cubit.state.limit, 80);
      cubit.setText('snel');
      expect(cubit.state.limit, 40);
      cubit.showMore();
      cubit.previousPeriod();
      expect(cubit.state.limit, 40);
      await cubit.close();
    });

    test('la période se partage par la mémoire ; le type demandé ne sert '
        'qu’une fois', () async {
      memory.requestTypeFilter('t-elec');
      final first = register();
      expect(first.state.query.typeIds, {'t-elec'});
      first.setGranularity(ExpenseGranularity.week);
      expect(memory.period.granularity, ExpenseGranularity.week);

      final second = register();
      expect(second.state.period.granularity, ExpenseGranularity.week);
      expect(second.state.query.typeIds, isEmpty);
      await first.close();
      await second.close();
    });

    test('enregistrer relit le registre', () async {
      var reads = 0;
      when(() => source.read()).thenAnswer((_) async {
        reads++;
        return Right(_snapshot([_expense('a')]));
      });
      when(() => save(any())).thenAnswer((_) async => Right(_expense('a')));
      final cubit = register();
      await cubit.load();
      await cubit.save(
        ExpenseDraft(
          typeId: 't',
          title: 'x',
          amountInCents: 1,
          currency: 'USD',
          expenseDate: _today,
        ),
      );
      expect(reads, 2);
      await cubit.close();
    });
  });

  group('ExpenseDashboardCubit', () {
    test('partage la période du registre et ne remonte jamais une relecture '
        'ratée', () async {
      memory.period = const ExpensePeriod(offset: -1);
      when(() => source.read()).thenAnswer(
        (_) async => Right(_snapshot([_expense('a', day: '2026-08-10')])),
      );
      final cubit = ExpenseDashboardCubit(
        source: source,
        memory: memory,
        now: () => _today,
      );
      await cubit.load();
      expect(cubit.state.period.offset, -1);
      expect(cubit.state.view.total.count, 1);

      when(
        () => source.read(),
      ).thenAnswer((_) async => const Left(StorageFailure('x')));
      changed();
      await pumpEventQueue();
      expect(cubit.state.status, ExpenseLoadStatus.ready);

      // « Voir le mois entier » depuis une semaine d'août ouvre AOÛT, pas le
      // mois en cours.
      cubit.setPeriod(
        const ExpensePeriod(granularity: ExpenseGranularity.week, offset: -2),
      );
      cubit.showWholeMonth();
      expect(memory.period, const ExpensePeriod(offset: -1));
      await cubit.close();
    });

    test(
      'fermé pendant la lecture : aucun abonnement laissé derrière',
      () async {
        when(
          () => source.read(),
        ).thenAnswer((_) async => Right(_snapshot(const [])));
        final cubit = ExpenseDashboardCubit(
          source: source,
          memory: memory,
          now: () => _today,
        );
        final loading = cubit.load();
        await cubit.close();
        await loading;
        verifyNever(() => source.watch(any()));
      },
    );
  });

  group('ExpensePeriodMemory', () {
    test('repart de zéro sous un autre compte ou une autre école', () {
      var owner = 'u-1@school-1';
      final scoped = ExpensePeriodMemory(owner: () => owner)
        ..period = const ExpensePeriod(offset: -2)
        ..requestTypeFilter('t-elec');
      expect(scoped.period.offset, -2);

      owner = 'u-2@school-1';
      expect(scoped.period, ExpensePeriod.initial);
      expect(scoped.takeTypeFilter(), isNull);
    });
  });
}
