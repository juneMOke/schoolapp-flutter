import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  ClassroomSummary classroom(String id, String name, int total) =>
      ClassroomSummary(
        id: id,
        schoolLevelId: 'lvl-$id',
        name: name,
        capacity: 40,
        totalCount: total,
        femaleCount: 0,
        maleCount: 0,
      );

  List<CourseSummary> buildCourses() => [
    CourseSummary(
      classroom: classroom('c1', '7e CTEB A', 18),
      courses: const [
        CourseRef(id: 'crs-1', label: 'Algèbre'),
        CourseRef(id: 'crs-2', label: 'Français'),
      ],
    ),
    CourseSummary(
      classroom: classroom('c2', '8e CTEB B', 22),
      courses: const [CourseRef(id: 'crs-3', label: 'Histoire')],
    ),
  ];

  /// Une classe pas encore descendue en local : on connaît les cours, pas la
  /// classe.
  CourseSummary unsyncedGroup() => CourseSummary(
    classroom: classroom('c-pending', '', 0),
    courses: const [
      CourseRef(id: 'crs-9', label: 'Géographie'),
      CourseRef(id: 'crs-10', label: 'Biologie'),
    ],
    classroomUnsynced: true,
  );

  testWidgets('une classe non synchronisée est masquée, et la mention le dit', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(MyCoursesSuccessView(courses: [...buildCourses(), unsyncedGroup()])),
    );
    await tester.pumpAndSettle();

    // Pas de carte anonyme : ni la classe sans nom, ni ses cours.
    expect(find.text('Géographie'), findsNothing);
    expect(find.text('Biologie'), findsNothing);
    // Mais l'utilisateur sait qu'ils existent et pourquoi ils manquent.
    expect(find.textContaining('classe non synchronisée'), findsOneWidget);
    expect(find.textContaining('2 cours masqués'), findsOneWidget);
    // Les classes normales, elles, sont bien là.
    expect(find.text('7e CTEB A'), findsOneWidget);
  });

  testWidgets('le compteur ne compte que ce qui est à l\'écran', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(MyCoursesSuccessView(courses: [...buildCourses(), unsyncedGroup()])),
    );
    await tester.pumpAndSettle();

    // 2 classes visibles et 3 cours — les 2 masqués n'y entrent pas, sinon le
    // compte serait invérifiable à l'œil.
    expect(find.textContaining('2 CLASSES · 3 COURS'), findsOneWidget);
  });

  testWidgets('aucune classe non synchronisée → aucune mention', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(MyCoursesSuccessView(courses: buildCourses())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('classe non synchronisée'), findsNothing);
  });

  testWidgets('affiche les classes et leurs cours, dépliés par défaut', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(MyCoursesSuccessView(courses: buildCourses())),
    );
    await tester.pumpAndSettle();

    expect(find.text('7e CTEB A'), findsOneWidget);
    expect(find.text('8e CTEB B'), findsOneWidget);
    expect(find.text('Algèbre'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Histoire'), findsOneWidget);
    // Tout est déplié -> la bascule propose « Tout replier ».
    expect(find.text('Tout replier'), findsOneWidget);
  });

  testWidgets('la bascule globale replie toutes les classes', (tester) async {
    await tester.pumpWidget(
      host(MyCoursesSuccessView(courses: buildCourses())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tout replier'));
    await tester.pumpAndSettle();

    // Corps replié : les branches sortent de l'arbre…
    expect(find.text('Algèbre'), findsNothing);
    expect(find.text('Histoire'), findsNothing);
    // …mais les en-têtes de classe restent visibles.
    expect(find.text('7e CTEB A'), findsOneWidget);
    expect(find.text('Tout déplier'), findsOneWidget);
  });

  testWidgets('aucun débordement sur écran étroit avec effectif long', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(300, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final courses = [
      CourseSummary(
        classroom: classroom('c1', '7e CTEB A', 9999),
        courses: const [CourseRef(id: '', label: 'Mathématiques approfondies')],
      ),
    ];

    await tester.pumpWidget(host(MyCoursesSuccessView(courses: courses)));
    await tester.pumpAndSettle();

    // Le texte « N élèves » ellipse au lieu de provoquer un RenderFlex overflow.
    expect(tester.takeException(), isNull);
    expect(find.text('7e CTEB A'), findsOneWidget);
  });
}
