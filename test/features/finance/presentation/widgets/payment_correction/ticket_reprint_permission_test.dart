import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/receipt_number_watch_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ticket_print_row.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_correction/facturation_payment_corrected_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_correction/payment_cancel_done_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakeReceipts implements PaymentReceiptResolver {
  @override
  Future<PaymentReceiptReference> resolve(String paymentId) async =>
      const PaymentReceiptReference(
        number: 'CF-RC-2627-000802',
        status: PaymentReceiptStatus.definitive,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Retour back du 2026-10-30 : imprimer exige `editique.read`, réimpression
/// comprise. Les deux écrans de fin de correction ne proposent alors aucun
/// ticket — même quand l'accusé de sync a déjà livré le numéro.
void main() {
  setUp(() {
    getIt.registerFactory<ReceiptNumberWatchCubit>(
      () => ReceiptNumberWatchCubit(_FakeReceipts()),
    );
  });

  tearDown(() => getIt.reset());

  Widget withPermissions(Widget child, List<String> permissions) {
    final auth = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, Stream<AuthState>.value(state), initialState: state);
    return BlocProvider<AuthBloc>.value(
      value: auth,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  const cancelPrint = ValueKey('payment-cancel-print-ticket');

  group('fin d annulation', () {
    Widget view() => PaymentCancelDoneView(paymentId: 'pay-1', onClose: () {});

    testWidgets('sans editique.read : aucun ticket d annulation', (
      tester,
    ) async {
      await tester.pumpWidget(
        withPermissions(view(), const ['finance.payment.cancel']),
      );
      await tester.pump();

      expect(find.byKey(cancelPrint), findsNothing);
      expect(
        find.byKey(const ValueKey('payment-correction-done-close')),
        findsOneWidget,
      );
    });

    testWidgets('avec editique.read : le ticket est proposé', (tester) async {
      await tester.pumpWidget(
        withPermissions(view(), const [
          'finance.payment.cancel',
          'editique.read',
        ]),
      );
      await tester.pump();

      expect(find.byKey(cancelPrint), findsOneWidget);
    });
  });

  group('versement corrigé', () {
    testWidgets('sans editique.read : pas de ticket du remplaçant', (
      tester,
    ) async {
      await tester.pumpWidget(
        withPermissions(
          const FacturationPaymentCorrectedDialog(
            replacementPaymentId: 'pay-2',
          ),
          const ['finance.payment.write'],
        ),
      );
      await tester.pump();

      expect(find.byType(FacturationTicketPrintRow), findsNothing);
      expect(
        find.byKey(const ValueKey('payment-correction-corrected-close')),
        findsOneWidget,
      );
    });
  });
}
