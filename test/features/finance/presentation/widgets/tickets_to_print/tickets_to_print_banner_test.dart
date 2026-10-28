import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/tickets_to_print/tickets_to_print_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../../test_helpers/reference_formats.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

class _Queue implements TicketPrintQueueRepository {
  List<TicketPrintJob> jobs = const [];

  @override
  Future<Either<Failure, List<TicketPrintJob>>> pendingJobs() async =>
      Right(jobs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TicketPrintJob _job(String id, {bool ready = true}) => TicketPrintJob(
  id: id,
  paymentId: 'p-$id',
  kind: TicketPrintJobKind.receipt,
  state: ready ? TicketPrintJobState.ready : TicketPrintJobState.awaitingNumber,
  receiptNumber: ready ? 'CF-RC-2627-00080$id' : null,
  studentFullName: 'Mbala Kasa Amina',
  amount: MoneyBag.empty,
  enteredAt: DateTime.utc(2026, 10, 12),
);

/// Le bandeau « n tickets prêts à imprimer » (continuité des tickets RC,
/// lot D).
void main() {
  late _Queue queue;
  late _MockSyncStatusCubit sync;

  setUp(() {
    queue = _Queue();
    sync = _MockSyncStatusCubit();
    whenListen(
      sync,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    getIt.registerFactory<TicketPrintQueueCubit>(
      () => TicketPrintQueueCubit(ListPendingTicketJobsUseCase(queue)),
    );
  });

  tearDown(() => getIt.reset());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: sync,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TicketsToPrintBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ne compte que les tickets prêts', (tester) async {
    queue.jobs = [_job('1'), _job('2'), _job('3', ready: false)];
    await open(tester);

    expect(find.text('2 tickets prêts à imprimer'), findsOneWidget);
    expect(find.text('Voir les tickets'), findsOneWidget);
  });

  testWidgets('masqué quand rien n est prêt', (tester) async {
    queue.jobs = [_job('3', ready: false)];
    await open(tester);

    expect(find.textContaining('prêt'), findsNothing);
  });

  testAtReferenceFormats('tient sur tous les formats', (tester, _) async {
    queue.jobs = [_job('1')];
    await open(tester);

    expect(find.text('1 ticket prêt à imprimer'), findsOneWidget);
  });
}
