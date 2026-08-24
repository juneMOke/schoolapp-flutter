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
    TextEditingController? phoneController,
    VoidCallback? onPickPayer,
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
            phoneController: phoneController ?? TextEditingController(),
            onPickPayer: onPickPayer,
            readOnly: readOnly,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder fieldByController(TextEditingController controller) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && identical(widget.controller, controller),
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

    await tester.enterText(
      fieldByController(lastNameController),
      'd\'angelo-kabeya',
    );
    await tester.enterText(fieldByController(firstNameController), 'jean paul');
    await tester.enterText(fieldByController(middleNameController), 'm\'bayo');
    await tester.pump();

    expect(lastNameController.text, 'D\'Angelo-Kabeya');
    expect(firstNameController.text, 'Jean Paul');
    expect(middleNameController.text, 'M\'Bayo');
  });

  /// L'étoile est un WIDGET, pas un `*` concaténé au libellé : on la cherche
  /// donc dans les spans, là où elle porte sa propre couleur — et non dans le
  /// texte du libellé, qui la laisserait passer pour de la ponctuation.
  Iterable<String> libellesEtoiles(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.textSpan is TextSpan)
        .where((t) {
          final span = t.textSpan! as TextSpan;
          return (span.children ?? const <InlineSpan>[]).any(
            (child) => child is TextSpan && child.text == ' *',
          );
        })
        .map((t) => (t.textSpan! as TextSpan).text ?? '');
  }

  testWidgets('les champs obligatoires portent l\'étoile, le post-nom non', (
    tester,
  ) async {
    final lastNameController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final phoneController = TextEditingController();

    addTearDown(lastNameController.dispose);
    addTearDown(firstNameController.dispose);
    addTearDown(middleNameController.dispose);
    addTearDown(phoneController.dispose);

    await pumpPayerSection(
      tester,
      lastNameController: lastNameController,
      firstNameController: firstNameController,
      middleNameController: middleNameController,
      phoneController: phoneController,
    );

    final etoiles = libellesEtoiles(tester).toList();

    expect(etoiles, contains('Nom'));
    expect(etoiles, contains('Prénom'));
    expect(etoiles, contains('Téléphone du payeur'));
    // Le post-nom reste facultatif : lui coller une étoile ferait chercher au
    // guichetier une information que personne ne lui demande.
    expect(
      etoiles.any((label) => label.startsWith('Post-nom')),
      isFalse,
      reason: 'le post-nom est le seul champ facultatif de la section',
    );
  });

  testWidgets('le bouton « Choisir un payeur » remonte le geste', (
    tester,
  ) async {
    final lastNameController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final phoneController = TextEditingController();

    addTearDown(lastNameController.dispose);
    addTearDown(firstNameController.dispose);
    addTearDown(middleNameController.dispose);
    addTearDown(phoneController.dispose);

    var ouvertures = 0;
    await pumpPayerSection(
      tester,
      lastNameController: lastNameController,
      firstNameController: firstNameController,
      middleNameController: middleNameController,
      phoneController: phoneController,
      onPickPayer: () => ouvertures++,
    );

    await tester.tap(find.text('Choisir un payeur'));
    await tester.pump();

    expect(ouvertures, 1);
  });

  /// Pendant un encaissement en vol, plus rien ne doit changer sous le
  /// formulaire — pas même par une reprise de payeur.
  testWidgets('en lecture seule, l\'ouverture de l\'annuaire est coupée', (
    tester,
  ) async {
    final lastNameController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final phoneController = TextEditingController();

    addTearDown(lastNameController.dispose);
    addTearDown(firstNameController.dispose);
    addTearDown(middleNameController.dispose);
    addTearDown(phoneController.dispose);

    var ouvertures = 0;
    await pumpPayerSection(
      tester,
      lastNameController: lastNameController,
      firstNameController: firstNameController,
      middleNameController: middleNameController,
      phoneController: phoneController,
      onPickPayer: () => ouvertures++,
      readOnly: true,
    );

    await tester.tap(find.text('Choisir un payeur'), warnIfMissed: false);
    await tester.pump();

    expect(ouvertures, 0);
  });
}
