import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/load_expense_thread_use_case.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_queue_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';

class _MockSource extends Mock implements ExpenseSnapshotSource {}

class _MockThread extends Mock implements LoadExpenseThreadUseCase {}

/// Un cas d'usage qui compte ses appels — et peut en refuser certains, pour
/// que le lot ait un échec à rapporter.
class _RecordingGesture implements ApplyExpenseGestureUseCase {
  final Set<String> refuses;
  final List<({String id, ExpenseGesture gesture, String note})> calls = [];

  _RecordingGesture({this.refuses = const {}});

  @override
  Future<Either<Failure, Unit>> call(
    Expense expense,
    ExpenseGesture gesture, {
    String note = '',
    String? actorName,
  }) async {
    calls.add((id: expense.id, gesture: gesture, note: note));
    if (refuses.contains(expense.id)) {
      return const Left(ConflictFailure('état changé'));
    }
    return const Right(unit);
  }
}

void main() {
  // Samedi 12 septembre 2026.
  final today = DateTime(2026, 9, 12);

  late _MockSource source;

  Expense expense(
    String id, {
    ExpenseStatus status = ExpenseStatus.pending,
    String day = '2026-09-10',
    int cents = 1000,
  }) => Expense(
    id: id,
    typeId: 'elec',
    title: 'Dépense $id',
    amountInCents: cents,
    currency: 'USD',
    status: status,
    expenseDate: DateTime.parse(day),
    clientUpdatedAt: DateTime.utc(2026),
  );

  ExpenseRegisterSnapshot snapshot(List<Expense> expenses) =>
      ExpenseRegisterSnapshot(types: const [], expenses: expenses);

  ExpenseQueueCubit build({ApplyExpenseGestureUseCase? gesture}) =>
      ExpenseQueueCubit(
        source: source,
        gesture: gesture ?? _RecordingGesture(),
        thread: _MockThread(),
        now: () => today,
      );

  setUp(() {
    source = _MockSource();
    when(() => source.watch(any())).thenReturn(() {});
  });

  void reads(List<Expense> expenses) => when(
    () => source.read(),
  ).thenAnswer((_) async => Right(snapshot(expenses)));

  test('charge la file, la plus ancienne en tête', () async {
    reads([
      expense('recente', day: '2026-09-11'),
      expense('vieille', day: '2026-09-02'),
    ]);
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, ExpenseLoadStatus.ready);
    expect(
      [for (final e in cubit.state.view.pending) e.id],
      ['vieille', 'recente'],
    );
  });

  test(
    'un registre illisible rend l\'écran en échec, pas une file vide',
    () async {
      when(
        () => source.read(),
      ).thenAnswer((_) async => const Left(StorageFailure('base illisible')));
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, ExpenseLoadStatus.failure);
      expect(cubit.state.failure, isA<StorageFailure>());
    },
  );

  test('changer de tri ne relit rien : la file tient en mémoire', () async {
    reads([
      expense('petite', cents: 100),
      expense('grosse', cents: 90000, day: '2026-09-11'),
    ]);
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setSort(ExpenseQueueSort.amount);

    expect(cubit.state.view.pending.first.id, 'grosse');
    verify(() => source.read()).called(1);
  });

  group('sélection', () {
    test('cocher, décocher, tout cocher', () async {
      reads([expense('a'), expense('b')]);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      cubit.toggleSelection('a');
      expect(cubit.state.selection, {'a'});
      expect(cubit.state.allSelected, isFalse);

      cubit.toggleAll();
      expect(cubit.state.allSelected, isTrue);

      cubit.toggleAll();
      expect(cubit.state.selection, isEmpty);
    });

    test(
      '« tout sélectionner » sur une file VIDE ne sélectionne rien',
      () async {
        reads([expense('payee', status: ExpenseStatus.paid)]);
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.load();

        cubit.toggleAll();

        expect(cubit.state.selection, isEmpty);
        expect(cubit.state.allSelected, isFalse);
      },
    );

    test('une ligne qui quitte la file quitte AUSSI la sélection', () async {
      // Sans cette purge, un lot suivant rejouerait un geste sur une demande
      // qu'un collègue vient de trancher.
      reads([expense('a'), expense('b')]);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      cubit.toggleAll();
      expect(cubit.state.selection, {'a', 'b'});

      reads([expense('a')]);
      await cubit.refresh();

      expect(cubit.state.selection, {'a'});
    });
  });

  group('lot', () {
    test('un geste PAR demande, le même motif recopié dans chacun', () async {
      reads([expense('a'), expense('b'), expense('c')]);
      final gesture = _RecordingGesture();
      final cubit = build(gesture: gesture);
      addTearDown(cubit.close);
      await cubit.load();
      cubit.toggleSelection('a');
      cubit.toggleSelection('c');

      final outcome = await cubit.applyBatch(
        cubit.selectedExpenses,
        ExpenseGesture.refuse,
        note: 'Devis non joint',
      );

      // Le back a retiré sa route de lot : le lot est un geste d'écran, et
      // chaque demande produit le sien.
      expect(gesture.calls.map((c) => c.id), ['a', 'c']);
      expect(gesture.calls.every((c) => c.note == 'Devis non joint'), isTrue);
      expect(outcome, (done: 2, failed: 0));
    });

    test('un lot part dans l\'ordre de la file, jamais en parallèle', () async {
      reads([
        expense('troisieme', day: '2026-09-11'),
        expense('premiere', day: '2026-09-02'),
        expense('deuxieme', day: '2026-09-05'),
      ]);
      final gesture = _RecordingGesture();
      final cubit = build(gesture: gesture);
      addTearDown(cubit.close);
      await cubit.load();
      cubit.toggleAll();

      await cubit.applyBatch(cubit.selectedExpenses, ExpenseGesture.approve);

      expect(gesture.calls.map((c) => c.id), [
        'premiere',
        'deuxieme',
        'troisieme',
      ]);
    });

    test('un refus au milieu du lot ne l\'arrête pas, et se compte', () async {
      reads([expense('a'), expense('b'), expense('c')]);
      final gesture = _RecordingGesture(refuses: {'b'});
      final cubit = build(gesture: gesture);
      addTearDown(cubit.close);
      await cubit.load();
      cubit.toggleAll();

      final outcome = await cubit.applyBatch(
        cubit.selectedExpenses,
        ExpenseGesture.approve,
      );

      expect(gesture.calls, hasLength(3));
      expect(outcome, (done: 2, failed: 1));
    });

    test('le lot vide la sélection quand il a fini', () async {
      reads([expense('a')]);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      cubit.toggleAll();

      await cubit.applyBatch(cubit.selectedExpenses, ExpenseGesture.approve);

      expect(cubit.state.selection, isEmpty);
    });
  });
}
