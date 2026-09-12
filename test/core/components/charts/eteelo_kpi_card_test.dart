import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La carte KPI tient son contenu, quel qu'il soit.
///
/// Sa hauteur était FIXÉE d'avance : un plancher par forme de carte, plus 22 px
/// par montant supplémentaire. Or une ligne de montant en gras 24 en occupe
/// davantage — dès qu'une sélection mêlait deux devises, la carte « Attendu »
/// débordait sous la bande des chiffres clés. Une police agrandie par le
/// téléphone suffisait, elle, à faire déborder n'importe quelle carte ; et un
/// libellé sur deux lignes, écrasé dans la place restante, perdait sa seconde
/// ligne sans que rien ne le signale.
final _mixed = EteeloKpiCardData(
  label: 'Attendu sur ces frais',
  valueLines: const ['4 250,00 \$', '1 500 000 FC'],
  subline: 'Deux devises : aucun total',
  accent: Colors.blue,
  accentSoft: Colors.white,
  icon: Icons.receipt_long_outlined,
);

const _counted = EteeloKpiCardData(
  label: 'N\'ont rien payé',
  value: 12,
  percent: 40,
  subline: 'Aucun versement',
  accent: Colors.red,
  accentSoft: Colors.white,
  icon: Icons.block,
);

const _plain = EteeloKpiCardData(
  label: 'Réglés',
  value: 3,
  accent: Colors.green,
  accentSoft: Colors.white,
  icon: Icons.check,
);

const _wordyLabel = 'Élèves dont le dossier attend encore une pièce';

const _wordy = EteeloKpiCardData(
  label: _wordyLabel,
  value: 7,
  accent: Colors.orange,
  accentSoft: Colors.white,
  icon: Icons.warning_amber_outlined,
);

final _band = [_mixed, _counted, _plain, _wordy];

Future<void> _pump(
  WidgetTester tester,
  List<EteeloKpiCardData> cards, {
  double textScale = 1.0,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        // Sans l'entrée animée : on mesure la carte, pas son apparition.
        disableAnimations: true,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 700, child: EteeloKpiBand(cards: cards)),
          ),
        ),
      ),
    ),
  ),
);

double _heightOf(WidgetTester tester, int index) =>
    tester.getSize(find.byType(EteeloKpiCard).at(index)).height;

/// Un texte est ÉCRASÉ quand sa boîte est moins haute que ses propres lignes :
/// le moteur le rogne alors en silence, sans la moindre exception.
bool _isSqueezed(WidgetTester tester, String text) {
  final box = tester.renderObject<RenderBox>(find.text(text));
  return box.size.height < box.getMaxIntrinsicHeight(box.size.width) - 0.01;
}

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('en police × $scale : aucun débordement, aucun texte rogné — '
        'deux devises et libellé sur deux lignes compris', (tester) async {
      await _pump(tester, _band, textScale: scale);

      expect(tester.takeException(), isNull);
      for (final text in [
        _mixed.label,
        _mixed.subline!,
        _counted.label,
        _counted.subline!,
        _plain.label,
        _wordyLabel,
      ]) {
        expect(_isSqueezed(tester, text), isFalse, reason: text);
      }
    });
  }

  testWidgets('quand le contenu tient, chaque carte garde sa hauteur '
      'historique — le plancher ne bouge pas d\'un pixel', (tester) async {
    await _pump(tester, _band);

    expect(
      _heightOf(tester, 0),
      AppDimensions.kpiCardHeightWithSubline +
          AppDimensions.kpiCardExtraValueHeight,
    );
    expect(_heightOf(tester, 1), AppDimensions.kpiCardHeightWithSubline);
    expect(_heightOf(tester, 2), AppDimensions.enrollmentStatsKpiCardHeight);
  });

  testWidgets('quand il ne tient plus, la carte GRANDIT au lieu de déborder', (
    tester,
  ) async {
    await _pump(tester, [_mixed], textScale: 2.0);

    expect(
      _heightOf(tester, 0),
      greaterThan(
        AppDimensions.kpiCardHeightWithSubline +
            AppDimensions.kpiCardExtraValueHeight,
      ),
    );
  });
}
