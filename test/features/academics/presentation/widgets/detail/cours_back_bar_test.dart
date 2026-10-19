import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_back_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Widget? trailing}) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CoursBackBar(
              brancheNom: 'Maths',
              classroomName: '6e A',
              onBack: () {},
              trailing: trailing,
            ),
          ),
        ),
      );

  testWidgets('l’action de la page se pose à droite du fil', (tester) async {
    await pump(
      tester,
      trailing: TextButton(onPressed: () {}, child: const Text('Nouveau')),
    );
    final crumb = tester.getRect(find.text('Maths · 6e A'));
    final action = tester.getRect(find.text('Nouveau'));
    expect(action.left, greaterThan(crumb.right));
  });

  testWidgets('sans action, le fil seul', (tester) async {
    await pump(tester);
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('Maths · 6e A'), findsOneWidget);
  });
}
