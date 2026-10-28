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
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/tickets_to_print_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

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
  String? number,
  String student = 'Mbala Kasa Amina',
  TicketPrintJobKind kind = TicketPrintJobKind.receipt,
  String? problem,
  bool receiptMissing = false,
}) => TicketPrintJob(
  id: id,
  paymentId: 'p-$id',
  kind: kind,
  state: receiptMissing
      ? TicketPrintJobState.receiptMissing
      : number == null
      ? TicketPrintJobState.awaitingNumber
      : TicketPrintJobState.ready,
  receiptNumber: number,
  studentFullName: student,
  amount: MoneyBag.of(const [Money(15000, 'USD'), Money(5000000, 'CDF')]),
  enteredAt: DateTime.utc(2026, 10, 12, 9, 30),
  lastProblem: problem,
);

final _mixed = [
  _job('1', number: 'CF-RC-2627-000802'),
  _job(
    '2',
    number: 'CF-RC-2627-000803',
    kind: TicketPrintJobKind.cancellation,
    student: 'Ngalula Tshimanga Marie-Christine Bénédicte',
    problem: 'unreachable',
  ),
  _job('3'),
];

/// « Tickets à imprimer » (continuité des tickets RC, lot D).
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
      () => TicketPrintQueueCubit(
        ListPendingTicketJobsUseCase(queue),
        RetryTicketReceiptUseCase(queue),
      ),
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
          home: TicketsToPrintPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool printEnabled(WidgetTester tester) {
    final button = find.ancestor(
      of: find.textContaining('Imprimer ('),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    return (tester.widget(button.first) as ButtonStyleButton).enabled;
  }

  testAtReferenceFormats('la file tient sur tous les formats', (
    tester,
    _,
  ) async {
    queue.result = Right([..._mixed, _job('4', receiptMissing: true)]);
    await open(tester);

    expect(find.text('Prêts à imprimer (2)'), findsOneWidget);
    expect(find.text('Numéro attendu (2)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Relancer'), 200);
    expect(find.text('Relancer'), findsOneWidget);
  });

  // Retour du back du 2026-10-28 : un accusé peut revenir sans reçu.
  testWidgets('un reçu non scellé se dit, et Relancer le redemande', (
    tester,
  ) async {
    final missing = _job('4', receiptMissing: true);
    queue.result = Right([missing]);
    await open(tester);

    expect(
      find.text('Reçu non scellé par le serveur : la tablette le redemande.'),
      findsOneWidget,
    );
    // Le reçu est revenu entre-temps.
    queue.result = Right([_job('4', number: 'CF-RC-2627-000804')]);
    await tester.tap(find.text('Relancer'));
    await tester.pumpAndSettle();

    expect(queue.retried, ['4']);
    expect(find.text('Prêts à imprimer (1)'), findsOneWidget);
  });

  testWidgets('les prêts se cochent, et le bouton compte la sélection', (
    tester,
  ) async {
    queue.result = Right(_mixed);
    await open(tester);
    expect(printEnabled(tester), isFalse);

    // La case de la première ligne ; la toute première est « Tout cocher ».
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(find.text('Imprimer (1)'), findsOneWidget);
    expect(printEnabled(tester), isTrue);

    await tester.tap(find.text('Tout cocher'));
    await tester.pump();
    expect(find.text('Imprimer (2)'), findsOneWidget);
  });

  testWidgets('un ticket qui attend son numéro ne se coche pas', (
    tester,
  ) async {
    queue.result = Right([_job('3')]);
    await open(tester);

    expect(find.text('Imprimer (0)'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('le dernier échec et le type se lisent sur la ligne', (
    tester,
  ) async {
    queue.result = Right(_mixed);
    await open(tester);

    expect(find.textContaining('Ticket d\'annulation'), findsOneWidget);
    expect(find.textContaining('Dernier échec'), findsOneWidget);
  });

  testWidgets('file vide : l état vide partagé', (tester) async {
    await open(tester);

    expect(find.byType(EteeloEmptyResult), findsOneWidget);
    expect(find.text('Aucun ticket en attente'), findsOneWidget);
  });

  testWidgets('file illisible : l état d erreur partagé', (tester) async {
    queue.result = const Left(StorageFailure('boom'));
    await open(tester);

    expect(find.byType(EteeloErrorResult), findsOneWidget);
  });
}
