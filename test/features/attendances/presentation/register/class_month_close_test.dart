import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_month_close.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'class_presence_fixtures.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Le bouton de clôture : seulement pour qui détient `attendance.amend`, et
/// seulement sur un mois terminé.
void main() {
  const teacher = ['attendance.read', 'attendance.write'];
  const prefect = ['attendance.read', 'attendance.write', 'attendance.amend'];

  ClassPresenceState stateOn(String month) => ClassPresenceState(
    load: ClassPresenceLoad.ready,
    today: '2026-10-01',
    day: '2026-10-01',
    month: month,
    classroom: kClassroom,
    schoolYear: const SchoolYearBounds(start: '2026-09-01'),
    tab: ClassPresenceTab.recap,
    monthData: ClassPresenceMonth(
      classroomId: 'c1',
      academicYearId: 'y1',
      month: month,
      students: [grace],
      calledDays: {'$month-01'},
      incidents: const {},
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    ClassPresenceState state,
    List<String> permissions,
  ) async {
    final auth = _Auth();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(auth, Stream.value(authState), initialState: authState);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: auth,
            child: ClassMonthCloseButton(state: state, recap: state.recap!),
          ),
        ),
      ),
    );
  }

  testWidgets('mois terminé, préfet : le bouton est offert', (tester) async {
    await pump(tester, stateOn('2026-09'), prefect);
    expect(find.text('Clôturer le mois'), findsOneWidget);
  });

  testWidgets('mois terminé, enseignant : pas de bouton', (tester) async {
    await pump(tester, stateOn('2026-09'), teacher);
    expect(find.text('Clôturer le mois'), findsNothing);
  });

  testWidgets('mois en cours : pas de bouton, même pour le préfet', (
    tester,
  ) async {
    await pump(tester, stateOn('2026-10'), prefect);
    expect(find.text('Clôturer le mois'), findsNothing);
  });

  test('la clôture compte les jours-élève sans appel', () {
    final recap = stateOn('2026-09').recap!;
    expect(recap, isA<ClassMonthRecap>());
    // 22 jours de classe en septembre 2026 depuis le 1er, un seul appelé.
    expect(recap.notMarked, recap.schoolDays - 1);
  });
}
