import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/recouvrement_call_list_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La liste à signer d'une classe de la simulation (O5) — **elle doit avoir
/// une taille**, et la garder dans ses trois états.
///
/// ⚠️ Le harnais monte `AppTheme.light`, et ce n'est pas décoratif : le thème
/// donne aux `FilledButton` une largeur minimale **infinie** (pensée pour les
/// CTA pleine largeur). Un tel bouton posé en enfant non-flex d'une `Row` lève
/// « BoxConstraints forces an infinite width » ; l'erreur est avalée pendant le
/// layout, la modale sort **sans taille**, et c'est le clic suivant qui éclate
/// sur « Cannot hit test a render box with no size ». Sous le thème par défaut
/// des tests, rien de tout cela n'apparaît.
RecoveryStudentRow _row(int index, {List<String> currencies = const ['CDF']}) =>
    RecoveryStudentRow(
      studentId: 'stu-$index',
      displayName: 'Nom$index Prénom$index',
      matriculationNumber: 'MAT-$index',
      due: [for (final c in currencies) Money(120000, c)],
      paid: [for (final c in currencies) Money(20000, c)],
      outstanding: [for (final c in currencies) Money(100000, c)],
      situation: StudentChargeStatus.partial,
      inOrder: false,
    );

void main() {
  /// Une tablette en **paysage** par défaut : c'est là que la hauteur manque,
  /// et le portrait masquerait le débordement du squelette.
  Future<void> pumpSheet(
    WidgetTester tester,
    List<RecoveryStudentRow>? students, {
    VoidCallback? onPrint,
    Size size = const Size(960, 528),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecouvrementCallListSheet.students(
            groupLabel: '1ère année',
            criterionLabel: "N'ont rien payé",
            students: students,
            onPrint: onPrint ?? () {},
          ),
        ),
      ),
    );
    // Pas de `pumpAndSettle` : le squelette scintille sans fin.
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Une modale sans taille lève ici même — `size` est inaccessible.
  void expectLaidOut(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Dialog)).isEmpty, isFalse);
  }

  FilledButton printButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(
      of: find.text('Imprimer'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    ),
  );

  testWidgets('en lecture : le squelette défile, « Imprimer » attend', (
    tester,
  ) async {
    await pumpSheet(tester, null);

    expectLaidOut(tester);
    expect(printButton(tester).onPressed, isNull);
  });

  testWidgets('liste vide : la modale tient debout, rien à imprimer', (
    tester,
  ) async {
    await pumpSheet(tester, const []);

    expectLaidOut(tester);
    expect(find.text('Aucun élève visé dans ce groupe.'), findsOneWidget);
    expect(printButton(tester).onPressed, isNull);
  });

  testWidgets('liste pleine : nom, matricule, case à signer et visas', (
    tester,
  ) async {
    var printed = 0;
    await pumpSheet(tester, [
      for (var i = 0; i < 40; i++) _row(i),
    ], onPrint: () => printed++);

    expectLaidOut(tester);
    expect(find.text('Élèves visés — 1ère année'), findsOneWidget);
    expect(find.text("40 élèves · N'ont rien payé"), findsOneWidget);
    expect(find.text('Nom0 Prénom0'), findsOneWidget);
    expect(find.text('MAT-0'), findsOneWidget);
    expect(find.text('Signature du parent'), findsOneWidget);

    await tester.tap(find.text('Imprimer'));
    await tester.pump();
    expect(printed, 1);

    await tester.scrollUntilVisible(
      find.text('Visa de la direction'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Visa du percepteur'), findsOneWidget);
  });

  testWidgets('deux devises : chaque montant s\'écrit par devise, jamais '
      'additionné', (tester) async {
    await pumpSheet(tester, [
      _row(0, currencies: const ['CDF', 'USD']),
    ]);

    expectLaidOut(tester);
    // Dû, payé et reste : une ligne par devise, aucune somme croisée.
    expect(find.textContaining('\$'), findsNWidgets(3));
  });

  testWidgets('téléphone : plein écran, sans débordement', (tester) async {
    await pumpSheet(tester, [
      for (var i = 0; i < 5; i++) _row(i),
    ], size: const Size(360, 740));

    expect(tester.takeException(), isNull);
    expect(find.text('Nom0 Prénom0'), findsOneWidget);
  });
}
