import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/helpers/avatar_palette.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(StudentAvatar),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  Future<void> pumpAvatar(WidgetTester tester, StudentAvatar avatar) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: avatar)),
      ),
    );
  }

  group('StudentAvatar — variante solid', () {
    testWidgets('fond = teinte d\'identité, initiales blancCasse', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        const StudentAvatar(
          firstName: 'Jean',
          lastName: 'Kabila',
          studentId: 's-1',
        ),
      );

      final deco = decorationOf(tester);
      expect(deco.color, AvatarPalette.colorFor('s-1'));
      expect(deco.border, isNull);

      final text = tester.widget<Text>(find.text('KJ'));
      expect(text.style!.color, AppColors.blancCasse);
    });
  });

  group('StudentAvatar — variante outlined', () {
    testWidgets('fond surfaceAlt, bordure + initiales = teinte', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        const StudentAvatar(
          firstName: 'Jean',
          lastName: 'Kabila',
          studentId: 's-1',
          variant: AvatarVariant.outlined,
        ),
      );

      final tint = AvatarPalette.colorFor('s-1');
      final deco = decorationOf(tester);
      expect(deco.color, AppColors.surfaceAlt);
      expect(deco.border, Border.all(color: tint, width: 1));

      final text = tester.widget<Text>(find.text('KJ'));
      expect(text.style!.color, tint);
    });
  });

  group('StudentAvatar — identité déterministe', () {
    testWidgets('même studentId → même teinte sur deux instances', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StudentAvatar(
                  firstName: 'Jean',
                  lastName: 'Kabila',
                  studentId: 'shared',
                ),
                StudentAvatar(
                  firstName: 'Marie',
                  lastName: 'Mbandu',
                  studentId: 'shared',
                ),
              ],
            ),
          ),
        ),
      );

      final decorations = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .whereType<Color>()
          .toList();

      expect(decorations.length, 2);
      expect(decorations[0], decorations[1]);
      expect(decorations[0], AvatarPalette.colorFor('shared'));
    });
  });

  group('StudentAvatar — accessibilité', () {
    testWidgets('semanticLabel fourni → annoncé par le lecteur d\'écran', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        const StudentAvatar(
          firstName: 'Jean',
          lastName: 'Kabila',
          studentId: 's-1',
          semanticLabel: 'Kabila Jean',
        ),
      );

      expect(find.bySemanticsLabel('Kabila Jean'), findsOneWidget);
    });

    testWidgets(
      'sans semanticLabel → initiales exclues de l\'arbre sémantique',
      (tester) async {
        await pumpAvatar(
          tester,
          const StudentAvatar(
            firstName: 'Jean',
            lastName: 'Kabila',
            studentId: 's-1',
          ),
        );

        // Les initiales restent rendues visuellement…
        expect(find.text('KJ'), findsOneWidget);
        // …mais ne sont pas exposées comme libellé sémantique.
        expect(find.bySemanticsLabel('KJ'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(StudentAvatar),
            matching: find.byType(ExcludeSemantics),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
