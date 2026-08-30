import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/money_bag_text.dart';

const String nbsp = ' ';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('mono-devise : un seul Text, comme avant', (tester) async {
    // C'est la propriété qui permet de remplacer les totaux existants sans
    // rien changer à l'écran tant qu'une seule devise circule.
    await _pump(
      tester,
      MoneyBagText(bag: MoneyBag.of(const [Money(42500, 'USD')])),
    );

    expect(find.byType(Text), findsOneWidget);
    expect(find.text('425,00$nbsp\$'), findsOneWidget);
    expect(find.byType(Column), findsNothing);
  });

  testWidgets('bi-devise : une ligne par devise, aucune somme', (tester) async {
    await _pump(
      tester,
      MoneyBagText(
        bag: MoneyBag.of(const [Money(42500, 'USD'), Money(9000000, 'CDF')]),
      ),
    );

    expect(find.byType(Text), findsNWidgets(2));
    expect(find.text('425,00$nbsp\$'), findsOneWidget);
    expect(find.text('90${nbsp}000${nbsp}FC'), findsOneWidget);
    // 42 500 + 9 000 000 centimes sommés feraient « 90 425 » — le nombre ne
    // peut apparaître que si quelqu'un a additionné deux unités.
    expect(find.textContaining('90${nbsp}425'), findsNothing);
  });

  testWidgets('l\'ordre suit celui du sac : code de devise croissant', (
    tester,
  ) async {
    await _pump(
      tester,
      MoneyBagText(
        bag: MoneyBag.of(const [Money(42500, 'USD'), Money(9000000, 'CDF')]),
      ),
    );

    final textes = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(textes.first, contains('FC'));
    expect(textes.last, contains(r'$'));
  });

  testWidgets('sac vide : le libellé de vide, jamais un zéro', (tester) async {
    // Sans créance, on ne sait pas dans quelle unité l'élève ne doit rien.
    await _pump(tester, const MoneyBagText(bag: MoneyBag.empty));

    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('0'), findsNothing);
  });

  testWidgets('le libellé de vide se surcharge', (tester) async {
    await _pump(
      tester,
      const MoneyBagText(bag: MoneyBag.empty, emptyLabel: 'Aucune créance'),
    );

    expect(find.text('Aucune créance'), findsOneWidget);
  });

  testWidgets('une entrée à zéro s\'affiche — ce n\'est pas un sac vide', (
    tester,
  ) async {
    // « En dollars, il ne reste rien » est une information ; « il ne doit rien,
    // dans aucune unité » en est une autre.
    await _pump(
      tester,
      MoneyBagText(bag: MoneyBag.of(const [Money(0, 'USD')])),
    );

    expect(find.text('0,00$nbsp\$'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('le style s\'applique à toutes les lignes', (tester) async {
    const style = TextStyle(fontSize: 21, color: Color(0xFF112233));
    await _pump(
      tester,
      MoneyBagText(
        bag: MoneyBag.of(const [Money(42500, 'USD'), Money(9000000, 'CDF')]),
        style: style,
      ),
    );

    for (final texte in tester.widgetList<Text>(find.byType(Text))) {
      expect(texte.style, style);
    }
  });

  testWidgets('trois devises tiennent sans déborder', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(
      tester,
      MoneyBagText(
        bag: MoneyBag.of(const [
          Money(42500, 'USD'),
          Money(9000000, 'CDF'),
          Money(1200, 'EUR'),
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsNWidgets(3));
  });
}
