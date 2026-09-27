import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_receipt_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockPaymentsBloc extends MockBloc<PaymentsEvent, PaymentsState>
    implements PaymentsBloc {}

class _MockResolver extends Mock implements PaymentReceiptResolver {}

class _MockPrintedAt extends Mock implements TicketPrintedAtUseCase {}

/// Régression du 27/09/2026 : « Annuler » et « Corriger » sortaient de la
/// page de facturation, et aucun geste n'atteignait le back.
///
/// La fiche s'ouvre sur le navigateur RACINE ; la page de facturation vit dans
/// une `ShellRoute`, donc dans un navigateur IMBRIQUÉ. Refermer la fiche avec
/// le contexte de la page dépilait la page. Ce test reproduit ce montage : un
/// test sans navigateur imbriqué passerait avec le défaut.
void main() {
  setUp(() {
    final payments = _MockPaymentsBloc();
    when(() => payments.state).thenReturn(const PaymentsState());
    getIt.registerFactory<PaymentsBloc>(() => payments);

    final resolver = _MockResolver();
    when(
      () => resolver.resolve(any()),
    ).thenAnswer((_) async => const PaymentReceiptReference(documentId: 'd'));
    getIt.registerFactory<PaymentReceiptCubit>(
      () => PaymentReceiptCubit(resolver),
    );

    final printedAt = _MockPrintedAt();
    when(() => printedAt(any())).thenAnswer((_) async => null);
    getIt.registerFactory<TicketPrintStatusCubit>(
      () => TicketPrintStatusCubit(printedAt),
    );
  });

  tearDown(() async => getIt.reset());

  final intent = FacturationPaymentDetailIntent(
    paymentId: 'pay-1',
    studentId: 'stu-1',
    academicYearId: 'ay-1',
    firstName: 'Gloredi',
    lastName: 'Tshiala',
    surname: 'Mbuyi',
    levelName: '6e A',
    levelGroupName: 'Secondaire',
    amounts: MoneyBag.of(const [Money(15000, 'USD')]),
    paidAt: DateTime(2026, 9, 25),
  );

  /// Ce que la page a reçu en retour de la fiche.
  FacturationPaymentDetailAction? returned;
  var dialogClosed = false;

  Future<void> openFromNestedPage(WidgetTester tester) async {
    returned = null;
    dialogClosed = false;
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Le navigateur imbriqué d'une coquille : la page de facturation y
        // vit, la fiche s'ouvre au-dessus, sur le navigateur racine.
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (pageContext) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    returned = await showFacturationPaymentDetailDialog(
                      pageContext,
                      intent: intent,
                    );
                    dialogClosed = true;
                  },
                  child: const Text('Page de facturation'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Page de facturation'));
    await tester.pumpAndSettle();
  }

  for (final (key, expected) in [
    ('payment-correction-cancel', FacturationPaymentDetailAction.cancel),
    ('payment-correction-correct', FacturationPaymentDetailAction.correct),
  ]) {
    testWidgets('$key referme la FICHE, pas la page, et rend le geste', (
      tester,
    ) async {
      await openFromNestedPage(tester);

      final button = find.byKey(ValueKey(key));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // La fiche est fermée et son geste revient à la page…
      expect(dialogClosed, isTrue);
      expect(returned, expected);
      expect(find.byKey(ValueKey(key)), findsNothing);
      // … qui, elle, est toujours là.
      expect(find.text('Page de facturation'), findsOneWidget);
    });
  }
}
