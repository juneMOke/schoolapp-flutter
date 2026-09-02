import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
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

  /// Le champ de saisie réel, retrouvé par le contrôleur que le test a fourni.
  ///
  /// On descend jusqu'au `TextField` : depuis le passage au socle, le widget
  /// exposé est un `EteeloTextInput` (libellé au-dessus du champ), et non plus
  /// un `TextFormField` — `enterText` a besoin du champ, pas de son enveloppe.
  Finder fieldByController(TextEditingController controller) {
    return find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is EteeloTextInput &&
            identical(widget.controller, controller),
      ),
      matching: find.byType(TextField),
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

  /// Depuis la V114 serveur, **aucun** champ de payeur n'est obligatoire :
  /// l'exigence se payait comptant au guichet, où le guichetier finissait par
  /// taper « X » pour faire avancer la file. Une étoile survivante promettrait
  /// un blocage qui n'existe plus, et ferait chercher une information que
  /// personne ne demande.
  testWidgets('aucun champ de la section ne porte plus d\'étoile', (
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

    expect(
      libellesEtoiles(tester),
      isEmpty,
      reason: 'le payeur est facultatif de bout en bout',
    );

    // Et la facultativité se DIT : sans mention, un guichetier qui a toujours
    // dû remplir ces champs continuera de les remplir, et l'assouplissement
    // n'aura rien changé à la file d'attente.
    expect(find.textContaining('facultatives'), findsOneWidget);
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
