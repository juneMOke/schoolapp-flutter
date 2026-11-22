import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_fee_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_fee_picker_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un frais, un nom — au contrôle des frais.
///
/// Chaque surface qui nomme une nature est éprouvée ici avec le MÊME catalogue :
/// l'école a renommé `TUITION` en « Frais scolaires annuels », et ce nom doit
/// apparaître partout où l'opérateur lit ce frais. (Le tableau de bord v2 nomme
/// ses frais par le libellé que le serveur renvoie : ses tests sont sous
/// `widgets/v2/`.)
const _title = 'Frais scolaires annuels';
const _titles = FeeSectionTitlesState(titles: {'TUITION': _title});

const _natures = [
  FeeNature(feeCode: 'TUITION', currencies: ['USD']),
  FeeNature(feeCode: 'REGISTRATION', currencies: ['USD']),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

RecouvrementFeePickerField _field({
  FeeSectionTitlesState titles = const FeeSectionTitlesState(),
  List<String> selected = const ['TUITION'],
}) => RecouvrementFeePickerField(
  natures: _natures,
  selected: selected,
  titles: titles,
  sheetTitle: 'Quels frais analyser ?',
  onChanged: (_) {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('l\'écran de contrôle', () {
    testWidgets('la pastille du choix des frais porte le titre de l\'école : '
        'le même nom que sa nature', (tester) async {
      await _pump(tester, _field(titles: _titles));

      expect(find.text(_title), findsOneWidget);
      expect(find.text('Frais de scolarité'), findsNothing);
    });

    testWidgets('sans titre sur l\'appareil, la nature localisée nomme', (
      tester,
    ) async {
      await _pump(tester, _field());

      expect(find.text('Frais de scolarité'), findsOneWidget);
      expect(find.text(_title), findsNothing);
    });

    testWidgets('les pastilles suivent l\'ordre que l\'école donne à ses '
        'sections', (tester) async {
      const titles = FeeSectionTitlesState(
        titles: {'REGISTRATION': 'Frais d\'inscription', 'TUITION': _title},
      );
      await _pump(
        tester,
        _field(
          titles: titles,
          // La question rangée comme le fait l'écran : l'ordre de l'école,
          // pas celui des clics ni celui du catalogue.
          selected: recouvrementSchoolOrder(const [
            'TUITION',
            'REGISTRATION',
          ], titles),
        ),
      );

      // Ordre de lecture : plus à gauche sur la même ligne, ou sur une ligne
      // au-dessus quand les pastilles s'enroulent (téléphone).
      final first = tester.getTopLeft(find.text('Frais d\'inscription'));
      final second = tester.getTopLeft(find.text(_title));
      expect(
        first.dy < second.dy || (first.dy == second.dy && first.dx < second.dx),
        isTrue,
        reason: 'inscription en $first, minerval en $second',
      );
    });

    testWidgets('la fiche d\'un élève nomme le frais comme sa pastille', (
      tester,
    ) async {
      await _pump(
        tester,
        const FeeControlFeeLine(
          charge: RecoveryChargePosition(
            feeCode: 'TUITION',
            position: FeeChargePosition(
              currency: 'USD',
              expectedInCents: 20000,
              paidMirrorInCents: 5000,
              paidPendingInCents: 0,
            ),
          ),
          sectionTitles: _titles,
        ),
      );

      expect(find.text(_title), findsOneWidget);
    });
  });
}
