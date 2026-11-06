import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/pages/cote_saisie_page.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_note_cell.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_panel.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_query.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/workspace/cote_workspace.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

class _MockYear
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockClassrooms
    extends MockBloc<ClassroomOfflineEvent, ClassroomOfflineState>
    implements ClassroomOfflineBloc {}

void main() {
  late FakeCotesRepository repository;
  late CoteSaisieBloc bloc;
  late CoteSaveCubit save;
  late _MockYear year;
  late _MockClassrooms classrooms;

  setUp(() {
    repository = FakeCotesRepository();
    bloc = CoteSaisieBloc(repository);
    save = CoteSaveCubit(repository);
    bloc.onCellWritten = save.noteChanged;
    year = _MockYear();
    classrooms = _MockClassrooms();
    const state = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(id: 'y', name: '2026', current: true),
        schoolLevelGroups: [],
      ),
    );
    when(() => year.state).thenReturn(state);
    when(() => classrooms.state).thenReturn(const ClassroomOfflineState());
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CoteSaisieBloc>.value(value: bloc),
          BlocProvider<CoteSaveCubit>.value(value: save),
          BlocProvider<AcademicYearContextBloc>.value(value: year),
          BlocProvider<ClassroomOfflineBloc>.value(value: classrooms),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(body: CoteSaisiePage()),
        ),
      ),
    );
    await tester.pump();
    addTearDown(() async {
      await tester.runAsync(() async {
        await save.close();
        await bloc.close();
      });
    });
  }

  late GoRouter router;

  /// La page à son adresse, une barre latérale de [sidebar] dp à sa gauche.
  Future<void> pumpRouted(
    WidgetTester tester, {
    required String location,
    Size size = const Size(1440, 1200),
    double sidebar = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/saisie',
          builder: (context, state) => Scaffold(
            body: Row(
              children: [
                SizedBox(width: sidebar),
                const Expanded(child: CoteSaisiePage()),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CoteSaisieBloc>.value(value: bloc),
          BlocProvider<CoteSaveCubit>.value(value: save),
          BlocProvider<AcademicYearContextBloc>.value(value: year),
          BlocProvider<ClassroomOfflineBloc>.value(value: classrooms),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pump();
    await tester.pump();
    addTearDown(() async {
      await tester.runAsync(() async {
        await save.close();
        await bloc.close();
      });
    });
  }

  String address() => router.routerDelegate.currentConfiguration.uri.toString();

  group('la largeur reçue, et non la fenêtre', () {
    testWidgets('une page étroite à côté d\'une barre latérale ouvre une '
        'seule colonne', (tester) async {
      await pumpRouted(tester, location: '/saisie?classe=c1', sidebar: 900);

      expect((bloc.state as CoteSaisieReady).scope.portee, CotePortee.colonne);
    });

    testWidgets('contre-épreuve : la même fenêtre sans barre ouvre le groupe', (
      tester,
    ) async {
      await pumpRouted(tester, location: '/saisie?classe=c1');

      expect((bloc.state as CoteSaisieReady).scope.portee, CotePortee.groupe);
      expect(address(), contains('portee=groupe'));
    });
  });

  group('la liste des élèves dans l\'adresse', () {
    Finder search() => find.descendant(
      of: find.byType(CoteStudentPanel),
      matching: find.byType(TextField),
    );

    testWidgets('un F5 retrouve la recherche et le filtre', (tester) async {
      await pumpRouted(
        tester,
        location: '/saisie?classe=c1&recherche=mba&filtre=todo',
      );

      expect(tester.widget<TextField>(search()).controller!.text, 'mba');
      final filter = tester.widget<SegmentedTabFilter<CoteStudentFilter>>(
        find.byType(SegmentedTabFilter<CoteStudentFilter>),
      );
      expect(filter.selected, CoteStudentFilter.todo);
      expect(find.textContaining('Tshala'), findsNothing);
    });

    testWidgets('la recherche tapée s\'écrit dans l\'adresse, « tous » non', (
      tester,
    ) async {
      await pumpRouted(tester, location: '/saisie?classe=c1');

      await tester.enterText(search(), 'tsh');
      await tester.pump();

      expect(address(), contains('recherche=tsh'));
      expect(address(), isNot(contains('filtre=')));
    });

    testWidgets('Ctrl+F va à la recherche des élèves', (tester) async {
      await pumpRouted(tester, location: '/saisie?classe=c1');
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<EditableText>()),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(of: search(), matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });
  });

  testWidgets('sans classe : l\'invite, et le bouton désactivé', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Choisissez une classe'), findsOneWidget);
    expect(find.text('Ouvrir la saisie'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une classe ouverte montre la portée et l\'espace de travail', (
    tester,
  ) async {
    await pumpPage(tester);

    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CoteWorkspace), findsOneWidget);
    // La carte de sélection s'est repliée : la portée vit derrière « Changer ».
    expect(find.text('Semestre 1'), findsOneWidget);
    expect(find.text('Un semestre'), findsNothing);
    expect(find.text('Ouvrir la saisie'), findsNothing);

    await tester.tap(find.text('Changer'));
    await tester.pump();

    expect(find.text('Un semestre'), findsOneWidget);
    expect(find.text('Ouvrir la saisie'), findsOneWidget);

    await tester.tap(find.text('Replier'));
    await tester.pump();

    expect(find.text('Un semestre'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une autre classe ouverte replie de nouveau la carte', (
    tester,
  ) async {
    await pumpPage(tester);
    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pump();
    await tester.tap(find.text('Changer'));
    await tester.pump();

    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pump();

    expect(find.text('Changer'), findsOneWidget);
    expect(find.text('Ouvrir la saisie'), findsNothing);
  });

  testWidgets('classe vide : changer de classe revient à l\'invite', (
    tester,
  ) async {
    repository = FakeCotesRepository(
      classe: const CoteClasse(
        classroomId: 'c1',
        decoupage: Decoupage.semestre,
        periodes: [],
        rubriques: [],
        eleves: [],
      ),
    );
    bloc = CoteSaisieBloc(repository);
    await pumpPage(tester);

    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieEmpty),
    );
    await tester.pump();

    await tester.tap(find.text('Changer de classe'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('Choisissez une classe'), findsOneWidget);
  });

  group('la frappe en cours', () {
    Future<void> openClass(WidgetTester tester) async {
      await pumpPage(tester);
      bloc.add(const CoteSaisieOpened('c1'));
      await tester.runAsync(
        () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
      );
      await tester.pump();
      await tester.pump();
    }

    RouteExitGuard guard(WidgetTester tester) =>
        tester.widget<RouteExitGuard>(find.byType(RouteExitGuard));

    testWidgets('une case tapée et non quittée retient la sortie ; partir '
        'l\'écrit, sans question', (tester) async {
      await openClass(tester);
      // Contre-épreuve : rien de tapé, rien à retenir.
      expect(guard(tester).hasUnsavedWork(), isFalse);

      await tester.tap(
        find
            .descendant(
              of: find.byType(CoteNoteCell),
              matching: find.byType(TextField),
            )
            .first,
      );
      await tester.pump();
      tester.testTextInput.enterText('14');
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(repository.saved, isEmpty);
      expect(guard(tester).hasUnsavedWork(), isTrue);

      final leaving = RouteExitGuard.mayLeave(
        tester.element(find.byType(CoteWorkspace)),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(await leaving, isTrue);
      expect(find.byType(Dialog), findsNothing);
      expect(repository.saved.single.$2, 14);
      expect(guard(tester).hasUnsavedWork(), isFalse);
    });

    testWidgets('partir envoie la dernière cote, pas seulement la file '
        'd\'avant', (tester) async {
      await openClass(tester);
      await tester.tap(
        find
            .descendant(
              of: find.byType(CoteNoteCell),
              matching: find.byType(TextField),
            )
            .first,
      );
      await tester.pump();
      tester.testTextInput.enterText('14');
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      repository.savedAtFlush.clear();

      var left = false;
      unawaited(
        Future.value(
          RouteExitGuard.mayLeave(tester.element(find.byType(CoteWorkspace))),
        ).then((leave) => left = leave),
      );
      for (var i = 0; i < 5 && !left; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }

      expect(left, isTrue);
      expect(repository.saved.single.$2, 14);
      // L'envoi de la sortie part APRÈS l'écriture de la case quittée : la
      // cote ne reste pas dans la file jusqu'à la synchro suivante.
      expect(repository.savedAtFlush, isNotEmpty);
      expect(repository.savedAtFlush.first, 1);
    });
  });
}
