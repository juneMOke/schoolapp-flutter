import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_coordinator_page.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

/// ADR-015 §6-B — l'emploi du temps s'ouvre avec `schedule.read` seul, que le
/// secrétariat et la discipline détiennent SANS aucun droit de notation
/// (`role_journeys_test.dart`). Le tap d'une cellule basculait pourtant vers la
/// page de notation, puis vers la grille nominative des notes.
///
/// La grille horaire reste entière — elle est scopée sur le compte connecté et
/// `schedule.read` est exactement le droit de la lire. C'est l'AFFORDANCE qui
/// est retirée : `onOpenCourse` nul se propage jusqu'aux chips et aux rangées,
/// qui cessent d'être tapables.
void main() {
  const enseignant = <String>['schedule.read', 'academics.course.read'];
  const secretariat = <String>['schedule.read'];

  Widget host(List<String> permissions) {
    final authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    // Contexte laissé en `initial` : la page s'arrête sur son indicateur de
    // chargement, donc aucun `TimetableBloc` n'est requis pour ce test.
    final yearBloc = _MockYearBloc();
    final yearState = const AcademicYearContextState.initial();
    when(() => yearBloc.state).thenReturn(yearState);
    whenListen(
      yearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: yearState,
    );

    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AcademicYearContextBloc>.value(value: yearBloc),
        ],
        child: const ScheduleCoordinatorPage(),
      ),
    );
  }

  testWidgets('avec academics.course.read : la cellule ouvre le détail', (
    tester,
  ) async {
    await tester.pumpWidget(host(enseignant));
    await tester.pump();

    final page = tester.widget<SchedulePage>(find.byType(SchedulePage));
    expect(page.onOpenCourse, isNotNull);
  });

  testWidgets('sans academics.course.read : la grille reste, sans porte', (
    tester,
  ) async {
    await tester.pumpWidget(host(secretariat));
    await tester.pump();

    // La grille est bien montée — on ne prive pas le profil de son emploi
    // du temps…
    expect(find.byType(SchedulePage), findsOneWidget);
    // … mais plus aucune cellule ne mène à la notation.
    final page = tester.widget<SchedulePage>(find.byType(SchedulePage));
    expect(page.onOpenCourse, isNull);
  });
}
