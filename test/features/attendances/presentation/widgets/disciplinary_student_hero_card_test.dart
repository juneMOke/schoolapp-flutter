import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_student_hero_card.dart';

void main() {
  Widget buildTestSubject({
    required String firstName,
    required String lastName,
    String? middleName,
    required String levelName,
    required String levelGroupName,
    String unknownValue = '-',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: DisciplinaryStudentHeroCard(
              unknownValue: unknownValue,
              firstName: firstName,
              lastName: lastName,
              middleName: middleName,
              levelName: levelName,
              levelGroupName: levelGroupName,
              levelLabel: 'Niveau',
              levelGroupLabel: 'Cycle',
            ),
          ),
        ),
      ),
    );
  }

  Finder richTextContaining(String text) => find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      );

  testWidgets(
    'affiche l avatar texte, le nom complet et les badges cycle/niveau',
    (tester) async {
      await tester.pumpWidget(
        buildTestSubject(
          firstName: 'Aline',
          lastName: 'Mukendi',
          middleName: 'Kabongo',
          levelName: '3e',
          levelGroupName: 'Secondaire',
        ),
      );

      expect(find.text('Mukendi Kabongo Aline'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.byIcon(Icons.gavel_outlined), findsNothing);
      expect(richTextContaining('Cycle · Secondaire'), findsOneWidget);
      expect(richTextContaining('Niveau · 3e'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'utilise le fallback pour le nom, l initiale et les badges si vide',
    (tester) async {
    await tester.pumpWidget(
      buildTestSubject(
        firstName: '',
        lastName: '',
        middleName: ' ',
        levelName: '',
        levelGroupName: '',
        unknownValue: '-',
      ),
    );

    expect(find.text('-'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.byIcon(Icons.gavel_outlined), findsNothing);
    expect(richTextContaining('Cycle · -'), findsOneWidget);
    expect(richTextContaining('Niveau · -'), findsOneWidget);
    expect(tester.takeException(), isNull);
    },
  );
}
