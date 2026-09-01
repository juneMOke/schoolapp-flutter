import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_option_tile.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_search_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panneau d'options ouvert — la partie que l'utilisateur voit APRÈS avoir
/// touché le champ, et qui portait jusqu'ici le menu Material d'origine.
void main() {
  List<EteeloSelectItem<String>> communes(int count) => [
    for (var i = 0; i < count; i++)
      EteeloSelectItem<String>(value: 'C$i', label: 'Commune $i'),
  ];

  Widget host({
    required List<EteeloSelectItem<String>> items,
    String? value,
    EteeloSelectPanelMode panelMode = EteeloSelectPanelMode.adaptive,
    Size size = const Size(1200, 800),
    ValueChanged<String?>? onChanged,
  }) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: EteeloSelectInput<String>(
                label: 'Commune',
                placeholder: 'Choisir',
                panelMode: panelMode,
                value: value,
                items: items,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  // On vise le champ lui-même : la colonne du select (libellé + champ) occupe
  // toute la hauteur offerte, son centre géométrique ne tombe donc pas sur la
  // zone cliquable.
  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.byType(EteeloSelectField));
    await tester.pumpAndSettle();
  }

  group('Forme du panneau', () {
    testWidgets('grand ecran : popover ancre, pas de feuille', (tester) async {
      await tester.pumpWidget(host(items: communes(3)));
      await openPanel(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(EteeloSelectOptionTile<String>), findsNWidgets(3));
    });

    testWidgets('petit ecran : feuille modale titree par le champ', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(items: communes(3), size: const Size(420, 900)),
      );
      await openPanel(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      // Le titre rappelle CE QU'ON remplit : la feuille couvre le formulaire.
      expect(find.text('Commune'), findsWidgets);
    });

    testWidgets('choisir une option remonte la valeur', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(items: communes(3), onChanged: (value) => picked = value),
      );
      await openPanel(tester);

      await tester.tap(find.text('Commune 2'));
      await tester.pumpAndSettle();

      expect(picked, 'C2');
    });
  });

  group('Recherche', () {
    testWidgets('absente sous le seuil', (tester) async {
      await tester.pumpWidget(host(items: communes(4)));
      await openPanel(tester);

      expect(find.byType(EteeloSelectSearchField), findsNothing);
    });

    testWidgets('presente au-dela du seuil, et filtre la liste', (
      tester,
    ) async {
      await tester.pumpWidget(host(items: communes(20)));
      await openPanel(tester);

      expect(find.byType(EteeloSelectSearchField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Commune 12');
      await tester.pumpAndSettle();

      // `find.text` verrait aussi la saisie de la recherche : on interroge la
      // ligne restante, pas le texte à l'écran.
      final remaining = tester.widget<EteeloSelectOptionTile<String>>(
        find.byType(EteeloSelectOptionTile<String>),
      );
      expect(remaining.item.label, 'Commune 12');
    });

    testWidgets('poste fixe : la recherche prend le focus d\'emblee', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      await tester.pumpWidget(host(items: communes(20)));
      await openPanel(tester);

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
        isTrue,
      );

      // Remis AVANT la fin du corps : le binding vérifie les variables de
      // debug entre le test et ses tearDown.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('tablette : le clavier logiciel ne monte pas tout seul', (
      tester,
    ) async {
      // `flutter_test` tourne en Android par défaut : rien à forcer ici.
      await tester.pumpWidget(host(items: communes(20)));
      await openPanel(tester);

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
        isFalse,
      );
      // Les fleches restent operantes : c'est le panneau qui porte le focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('une recherche sans reponse le dit', (tester) async {
      await tester.pumpWidget(host(items: communes(20)));
      await openPanel(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.byType(EteeloSelectOptionTile<String>), findsNothing);
      expect(find.text('Aucune option ne correspond'), findsOneWidget);
    });
  });

  group('Clavier', () {
    testWidgets('fleche bas puis entree choisit sans quitter le clavier', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        host(items: communes(20), onChanged: (value) => picked = value),
      );
      await openPanel(tester);

      // La surbrillance part de la premiere option : une descente puis entree
      // valide la deuxieme.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(picked, 'C1');
    });

    testWidgets('echap referme sans rien changer', (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        host(items: communes(20), onChanged: (_) => changes++),
      );
      await openPanel(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(EteeloSelectOptionTile<String>), findsNothing);
      expect(changes, 0);
    });

    testWidgets('le champ ferme s\'ouvre a la fleche bas', (tester) async {
      await tester.pumpWidget(host(items: communes(3)));

      await openPanel(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(EteeloSelectOptionTile<String>), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byType(EteeloSelectOptionTile<String>), findsNWidgets(3));
    });
  });

  group('Etat de la ligne', () {
    testWidgets('l\'option courante est cochee', (tester) async {
      await tester.pumpWidget(host(items: communes(3), value: 'C1'));
      await openPanel(tester);

      final tiles = tester
          .widgetList<EteeloSelectOptionTile<String>>(
            find.byType(EteeloSelectOptionTile<String>),
          )
          .toList();
      expect(tiles.where((t) => t.isSelected).length, 1);
      expect(tiles.firstWhere((t) => t.isSelected).item.value, 'C1');
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('une option desactivee ne se choisit pas', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          items: const [
            EteeloSelectItem(value: 'A', label: 'Ouverte'),
            EteeloSelectItem(value: 'B', label: 'Fermee', enabled: false),
          ],
          onChanged: (value) => picked = value,
        ),
      );
      await openPanel(tester);

      await tester.tap(find.text('Fermee'));
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });
  });
}
