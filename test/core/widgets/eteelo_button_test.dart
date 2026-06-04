import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

void main() {
  group('EteeloButton', () {
    Future<void> pumpButton(WidgetTester tester, Widget button) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 320, child: button)),
          ),
        ),
      );
    }

    testWidgets('primary applique les couleurs attendues', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.primary(label: 'Rechercher', onPressed: () {}),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final background = button.style?.backgroundColor?.resolve(
        <WidgetState>{},
      );
      final foreground = button.style?.foregroundColor?.resolve(
        <WidgetState>{},
      );

      expect(background, AppColors.terreCuite);
      expect(foreground, AppColors.blancCasse);
    });

    testWidgets('secondary utilise une bordure bleu ardoise 1.5', (
      tester,
    ) async {
      await pumpButton(
        tester,
        EteeloButton.secondary(label: 'Reinitialiser', onPressed: () {}),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final side = button.style?.side?.resolve(<WidgetState>{});

      expect(side?.color, AppColors.bleuArdoise);
      expect(side?.width, 1.5);
    });

    testWidgets('ghost rend un TextButton sans bordure', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.ghost(label: 'Reinitialiser', onPressed: () {}),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('danger applique le fond error', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.danger(label: 'Supprimer', onPressed: () {}),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final background = button.style?.backgroundColor?.resolve(
        <WidgetState>{},
      );

      expect(background, AppColors.error);
    });

    testWidgets('isLoading affiche un spinner et desactive la semantics', (
      tester,
    ) async {
      var tapCount = 0;
      await pumpButton(
        tester,
        EteeloButton.primary(
          label: 'Enregistrer',
          isLoading: true,
          onPressed: () => tapCount++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final semanticsNode = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Enregistrer',
        ),
      );
      expect(
        semanticsNode,
        matchesSemantics(
          label: 'Enregistrer',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapCount, 0);
    });

    testWidgets('focus affiche un ring de focus', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.primary(label: 'Continuer', onPressed: () {}),
      );

      final before = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final beforeDecoration = before.decoration! as BoxDecoration;
      expect(beforeDecoration.boxShadow, isEmpty);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      button.focusNode?.requestFocus();
      await tester.pumpAndSettle();

      final after = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final afterDecoration = after.decoration! as BoxDecoration;
      expect(afterDecoration.boxShadow, isNotEmpty);
      expect(afterDecoration.boxShadow!.first.color, AppColors.stateFocus);
      expect(afterDecoration.boxShadow!.first.spreadRadius, 2);
    });

    testWidgets('size regular prend toute la largeur et hauteur 48', (
      tester,
    ) async {
      await pumpButton(
        tester,
        EteeloButton.primary(
          label: 'Valider',
          size: EteeloButtonSize.regular,
          onPressed: () {},
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == double.infinity,
        ),
        findsOneWidget,
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final minimumSize = button.style?.minimumSize?.resolve(<WidgetState>{});
      final shape = button.style?.shape?.resolve(<WidgetState>{});

      expect(minimumSize, const Size(0, 48));
      expect(shape, isA<StadiumBorder>());
    });

    testWidgets('size regular respecte fullWidth false', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.primary(
          label: 'Valider',
          size: EteeloButtonSize.regular,
          fullWidth: false,
          onPressed: () {},
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == double.infinity,
        ),
        findsNothing,
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final minimumSize = button.style?.minimumSize?.resolve(<WidgetState>{});
      expect(minimumSize, const Size(0, 48));
    });

    testWidgets('size compact applique une hauteur sm de 40', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.primary(label: 'Valider', onPressed: () {}),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final minimumSize = button.style?.minimumSize?.resolve(<WidgetState>{});
      expect(minimumSize, const Size(112, 40));
    });

    testWidgets('icones respectent md=18 et sm=16', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.primary(
          label: 'Valider',
          icon: Icons.check,
          size: EteeloButtonSize.regular,
          onPressed: () {},
        ),
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).size, 18);

      await pumpButton(
        tester,
        EteeloButton.primary(
          label: 'Valider',
          icon: Icons.check,
          onPressed: () {},
        ),
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).size, 16);
    });

    testWidgets('ghost applique un padding horizontal de 8', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.ghost(label: 'Effacer', onPressed: () {}),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      final padding = button.style?.padding?.resolve(<WidgetState>{});
      expect(padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 0));
    });

    testWidgets('label utilise 500 / 14 / 1.2', (tester) async {
      await pumpButton(
        tester,
        EteeloButton.primary(label: 'Valider', onPressed: () {}),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style?.textStyle?.resolve(<WidgetState>{});
      expect(style?.fontWeight, FontWeight.w500);
      expect(style?.fontSize, 14);
      expect(style?.height, 1.2);
    });

    testWidgets('onPressed null rend le bouton desactive', (tester) async {
      await pumpButton(
        tester,
        const EteeloButton.primary(label: 'Rechercher', onPressed: null),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      final semanticsNode = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Rechercher',
        ),
      );
      expect(
        semanticsNode,
        matchesSemantics(
          label: 'Rechercher',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
    });
  });
}
