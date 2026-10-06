import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_programme_editor.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  late List<String> emitted;

  Widget host(List<String> lines, {VoidCallback? onReprendre}) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SujetProgrammeEditor(
        lines: lines,
        onChanged: (l) => emitted = l,
        onReprendreChapitres: onReprendre,
      ),
    ),
  );

  setUp(() => emitted = const []);

  testWidgets('« Ajouter un point » ouvre une ligne', (tester) async {
    await tester.pumpWidget(host(const []));
    await tester.tap(find.text('Ajouter un point'));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(emitted, ['']);
  });

  testWidgets('Entrée ajoute une ligne dessous', (tester) async {
    await tester.pumpWidget(host(const ['Réactions']));
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(emitted, ['Réactions', '']);
  });

  testWidgets('Retour arrière sur une ligne vide la supprime', (tester) async {
    await tester.pumpWidget(host(const ['A', '']));
    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(emitted, ['A']);
  });

  testWidgets('« Reprendre les chapitres » seulement si la liste est vide', (
    tester,
  ) async {
    await tester.pumpWidget(host(const [], onReprendre: () {}));
    expect(find.text('Reprendre les chapitres'), findsOneWidget);

    await tester.pumpWidget(host(const ['A'], onReprendre: () {}));
    expect(find.text('Reprendre les chapitres'), findsNothing);
  });
}
