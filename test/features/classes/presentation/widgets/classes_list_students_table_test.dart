import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_students_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fixture choisie pour que l'ordre par **niveau** et l'ordre par **nom** ne
/// coïncident dans aucun sens : sans ça, un test d'ordre ne prouverait rien.
const _rows = [
  ClassesListStudentRow(
    id: 's1',
    studentId: 's1',
    lastName: 'Kabongo',
    surname: 'Mwamba',
    firstName: 'Daniel',
    levelLabel: '1ère',
  ),
  ClassesListStudentRow(
    id: 's2',
    studentId: 's2',
    lastName: 'Ilunga',
    surname: 'Tshibola',
    firstName: 'Grace',
    levelLabel: '5ème',
  ),
  ClassesListStudentRow(
    id: 's3',
    studentId: 's3',
    lastName: 'Abedi',
    surname: 'Bope',
    firstName: 'Sarah',
    // Référentiel pas encore descendu pour cet élève.
    levelLabel: '',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  List<ClassesListStudentRow> rows = _rows,
  bool showLevelColumn = false,
  int? totalCount,
  int currentPage = 1,
  int totalPages = 1,
  int pageSize = 10,
  VoidCallback? onPreviousPage,
  VoidCallback? onNextPage,
}) async {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: ClassesListStudentsTable(
          rows: rows,
          showLevelColumn: showLevelColumn,
          totalCount: totalCount,
          currentPage: currentPage,
          totalPages: totalPages,
          pageSize: pageSize,
          onPreviousPage: onPreviousPage,
          onNextPage: onNextPage,
          onViewRequested: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Vrai si la ligne portant [first] est rendue au-dessus de celle de [second].
bool _isAbove(WidgetTester tester, String first, String second) =>
    tester.getTopLeft(find.text(first)).dy <
    tester.getTopLeft(find.text(second)).dy;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sans la colonne Niveau : trois colonnes, aucun niveau rendu', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('NIVEAU'), findsNothing);
    expect(find.text('5ème'), findsNothing);
    expect(find.text('Kabongo'), findsOneWidget);
  });

  testWidgets('avec la colonne Niveau : l\'en-tête et la valeur apparaissent', (
    tester,
  ) async {
    await _pump(tester, showLevelColumn: true);

    expect(find.text('NIVEAU'), findsOneWidget);
    expect(find.text('5ème'), findsOneWidget);
  });

  testWidgets('un niveau que la ligne ne sait pas dire se montre comme tel', (
    tester,
  ) async {
    await _pump(tester, showLevelColumn: true);

    // Une cellule vide se lirait comme « cet élève n'a pas de niveau », alors
    // que le référentiel est simplement en retard.
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('le tri par niveau réordonne les lignes', (tester) async {
    await _pump(tester, showLevelColumn: true);

    await tester.tap(find.text('NIVEAU'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('5ème'), findsOneWidget);
  });

  testWidgets(
    'trier par niveau puis retirer la colonne ne laisse pas un tri fantôme',
    (tester) async {
      await _pump(tester, showLevelColumn: true);
      // Deux taps : le premier active la colonne (ascendant), le second inverse
      // — descendant, « 5ème » passe devant le niveau inconnu.
      await tester.tap(find.text('NIVEAU'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NIVEAU'));
      await tester.pumpAndSettle();
      expect(
        _isAbove(tester, 'Ilunga', 'Kabongo'),
        isTrue,
        reason: '« 5ème » passe devant « 1ère » en descendant',
      );

      // Même état de widget (pas de nouvelle clé) : c'est le passage d'une
      // recherche par identité à une recherche par classe.
      await _pump(tester, showLevelColumn: false);

      expect(find.text('NIVEAU'), findsNothing);
      // Le tri retombe sur le Nom — même sens (descendant), colonne visible.
      // Sans repli, les lignes resteraient ordonnées par une colonne invisible.
      expect(
        _isAbove(tester, 'Kabongo', 'Ilunga'),
        isTrue,
        reason: 'ordre du Nom descendant, pas l\'ordre du niveau caché',
      );
    },
  );

  testWidgets('une seule page : aucune pagination', (tester) async {
    await _pump(
      tester,
      totalPages: 1,
      onNextPage: () {},
      onPreviousPage: () {},
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('plusieurs pages : la pagination apparaît et avance', (
    tester,
  ) async {
    var nextCalls = 0;
    await _pump(
      tester,
      totalCount: 42,
      currentPage: 1,
      totalPages: 5,
      onPreviousPage: () {},
      onNextPage: () => nextCalls++,
    );

    final next = find.byIcon(Icons.chevron_right_rounded);
    expect(next, findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(nextCalls, 1);
  });
}
