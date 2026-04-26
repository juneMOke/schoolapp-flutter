import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPayerSection(
    WidgetTester tester, {
    required TextEditingController lastNameController,
    required TextEditingController firstNameController,
    required TextEditingController middleNameController,
    bool readOnly = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FacturationCreatePaymentPayerSection(
            lastNameController: lastNameController,
            firstNameController: firstNameController,
            middleNameController: middleNameController,
            readOnly: readOnly,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder fieldByController(TextEditingController controller) {
    return find.byWidgetPredicate(
      (widget) => widget is TextFormField && identical(widget.controller, controller),
    );
  }

  testWidgets('applique le formatter majuscule sur les trois champs payeur', (
    tester,
  ) async {
    final lastNameController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();

    addTearDown(lastNameController.dispose);
    addTearDown(firstNameController.dispose);
    addTearDown(middleNameController.dispose);

    await pumpPayerSection(
      tester,
      lastNameController: lastNameController,
      firstNameController: firstNameController,
      middleNameController: middleNameController,
    );

    await tester.enterText(fieldByController(lastNameController), 'd\'angelo-kabeya');
    await tester.enterText(fieldByController(firstNameController), 'jean paul');
    await tester.enterText(fieldByController(middleNameController), 'm\'bayo');
    await tester.pump();

    expect(lastNameController.text, 'D\'Angelo-Kabeya');
    expect(firstNameController.text, 'Jean Paul');
    expect(middleNameController.text, 'M\'Bayo');
  });
}
