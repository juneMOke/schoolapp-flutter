import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDialogHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => showCreatePaymentConfirmDialog(context),
                    child: const Text('open-payment-dialog'),
                  ),
                  TextButton(
                    onPressed: () => showAppConfirmationDialog(
                      context: context,
                      title: 'Supprimer allocation',
                      message: 'Confirmer la suppression',
                      confirmLabel: 'Supprimer',
                      cancelLabel: 'Annuler',
                      isDestructive: true,
                      headerIcon: Icons.delete_sweep_outlined,
                      headerIconColor: AppColors.danger,
                      headerIconBackgroundColor: AppColors.financeDetailDangerSoft,
                      confirmIcon: Icons.delete_forever_outlined,
                    ),
                    child: const Text('open-delete-dialog'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche une popin metier paiement avec icones de validation', (
    tester,
  ) async {
    await pumpDialogHost(tester);

    await tester.tap(find.text('open-payment-dialog'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('affiche une popin suppression avec iconographie destructive', (
    tester,
  ) async {
    await pumpDialogHost(tester);

    await tester.tap(find.text('open-delete-dialog'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_forever_outlined), findsOneWidget);
    expect(find.byIcon(Icons.payments_outlined), findsNothing);
  });
}
