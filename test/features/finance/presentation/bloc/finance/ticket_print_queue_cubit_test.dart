import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';

class _Queue implements TicketPrintQueueRepository {
  Either<Failure, List<TicketPrintJob>> result = const Right([]);

  final List<String> retried = [];

  @override
  Future<Either<Failure, List<TicketPrintJob>>> pendingJobs() async => result;

  @override
  Future<Either<Failure, Unit>> retryReceipt(TicketPrintJob job) async {
    retried.add(job.id);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TicketPrintJob _job(
  String id, {
  TicketPrintJobState state = TicketPrintJobState.ready,
}) => TicketPrintJob(
  id: id,
  paymentId: 'p-$id',
  kind: TicketPrintJobKind.receipt,
  state: state,
  receiptNumber: state == TicketPrintJobState.awaitingNumber
      ? null
      : state == TicketPrintJobState.receiptMissing
      ? null
      : 'CF-RC-2627-00080$id',
  studentFullName: 'Mbala Kasa Amina',
  amount: MoneyBag.empty,
  enteredAt: DateTime.utc(2026, 10, 12),
);

/// La sélection de « Tickets à imprimer » (continuité des tickets RC, lot D).
void main() {
  late _Queue queue;
  late TicketPrintQueueCubit cubit;

  setUp(() {
    queue = _Queue();
    cubit = TicketPrintQueueCubit(
      ListPendingTicketJobsUseCase(queue),
      RetryTicketReceiptUseCase(queue),
    );
  });

  tearDown(() => cubit.close());

  test('un ticket qui attend ne se coche pas', () async {
    queue.result = Right([
      _job('1'),
      _job('2', state: TicketPrintJobState.awaitingNumber),
      _job('3', state: TicketPrintJobState.awaitingStudent),
    ]);
    await cubit.load();

    cubit
      ..toggle('2', true)
      ..toggle('3', true)
      ..toggle('1', true);

    expect(cubit.state.selected, {'1'});
  });

  test('tout cocher ne coche que les prêts', () async {
    queue.result = Right([
      _job('1'),
      _job('2'),
      _job('3', state: TicketPrintJobState.awaitingNumber),
    ]);
    await cubit.load();

    cubit.toggleAll(true);

    expect(cubit.state.selected, {'1', '2'});
    expect(cubit.state.allReadySelected, isTrue);
  });

  test('relire réduit la sélection aux tickets encore prêts', () async {
    queue.result = Right([_job('1'), _job('2')]);
    await cubit.load();
    cubit.toggleAll(true);

    // « 1 » est sorti, « 2 » reste.
    queue.result = Right([_job('2')]);
    await cubit.load();

    expect(cubit.state.selected, {'2'});
  });

  test('une file illisible se dit, sans effacer ce qui était lu', () async {
    queue.result = const Left(StorageFailure('boom'));
    await cubit.load();

    expect(cubit.state.phase, TicketPrintQueuePhase.failure);
  });

  test('Relancer redemande le reçu puis relit la file', () async {
    final missing = _job('1', state: TicketPrintJobState.receiptMissing);
    queue.result = Right([missing]);
    await cubit.load();

    // Le reçu est revenu entre-temps.
    queue.result = Right([_job('1')]);
    await cubit.retryReceipt(missing);

    expect(queue.retried, ['1']);
    expect(cubit.state.ready.single.id, '1');
    expect(cubit.state.retrying, isEmpty);
  });
}
