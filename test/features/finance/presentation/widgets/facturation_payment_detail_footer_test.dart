import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_footer.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ticket_print_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _FakeRepository implements ProvisionalTicketRepository {
  _FakeRepository({this.printedAt});

  final DateTime? printedAt;

  @override
  Future<DateTime?> ticketPrintedAt(String paymentId) async => printedAt;

  @override
  Future<void> markTicketPrinted(String paymentId) async {}

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async => throw UnimplementedError();
}

/// L'impression du ticket est le bouton PRINCIPAL du détail d'un versement :
/// au guichet, c'est ce que le parent attend.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    DateTime? printedAt,
  }) async {
    final cubit = TicketPrintStatusCubit(
      TicketPrintedAtUseCase(_FakeRepository(printedAt: printedAt)),
    );
    addTearDown(cubit.close);
    await cubit.load('pay-1');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<TicketPrintStatusCubit>.value(
            value: cubit,
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  EteeloButton primaryOf(WidgetTester tester) => tester
      .widgetList<EteeloButton>(find.byType(EteeloButton))
      .firstWhere((b) => b.label != 'Télécharger le reçu');

  Widget footer({String? ticketPaymentId = 'pay-1'}) =>
      FacturationPaymentDetailFooter(
        ticketPaymentId: ticketPaymentId,
        onDownloadReceipt: () {},
        onClose: () {},
      );

  testWidgets('imprimer le ticket prend la place de « Fermer »', (
    tester,
  ) async {
    await pump(tester, footer());

    final primary = primaryOf(tester);
    expect(primary.label, 'Imprimer le ticket');
    expect(primary.icon, Icons.print_outlined);
    expect(primary.onPressed, isNotNull);
    expect(find.text('Fermer'), findsNothing);
    expect(find.text('Télécharger le reçu'), findsOneWidget);
  });

  testWidgets('un ticket déjà sorti se réimprime', (tester) async {
    await pump(tester, footer(), printedAt: DateTime(2026, 9, 25, 13, 12));

    expect(primaryOf(tester).label, 'Réimprimer le ticket');
  });

  // Reçu retiré ou versement annulé : aucun papier ne doit plus sortir.
  testWidgets('sans ticket offert, le pied redevient « Fermer »', (
    tester,
  ) async {
    await pump(tester, footer(ticketPaymentId: null));

    expect(primaryOf(tester).label, 'Fermer');
    expect(find.byIcon(Icons.print_outlined), findsNothing);
  });

  // Dans le détail, la ligne ne dit plus que l'état : deux boutons pour le
  // même geste se liraient comme deux gestes.
  testWidgets('la ligne d état n a plus de bouton dans le détail', (
    tester,
  ) async {
    await pump(
      tester,
      const FacturationTicketPrintRow(paymentId: 'pay-1', showAction: false),
      printedAt: DateTime(2026, 9, 25, 13, 12),
    );

    expect(find.text('Imprimé le 25/09/2026 13:12'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });
}
