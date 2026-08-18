import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Read-your-writes du listing Première inscription : au RETOUR du wizard, la
/// page doit re-lire la base locale. Sans ce câblage, le dossier qu'on vient
/// de finaliser reste affiché avec son ancien badge « Brouillon ».
class _MockLocalListBloc extends Mock implements EnrollmentLocalListBloc {}

class _MockAcademicYearBloc extends Mock implements AcademicYearContextBloc {}

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const LocalListRefreshRequested());
    registerFallbackValue(const AcademicYearContextRequested());
  });

  late _MockLocalListBloc listBloc;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;

  const draftRow = EnrollmentSummary(
    enrollmentId: 'draft-1',
    enrollmentCode: '',
    status: 'IN_PROGRESS',
    enrollmentType: 'NEW_ENROLLMENT',
    syncState: SyncState.draft,
    student: StudentSummary(
      id: 'stu-1',
      firstName: 'Jean',
      lastName: 'Kanku',
      surname: 'Mbuyi',
      dateOfBirth: '2012-05-20',
      gender: Gender.male,
    ),
  );

  setUp(() {
    listBloc = _MockLocalListBloc();
    final listState = const EnrollmentLocalListState.initial().copyWith(
      summariesStatus: EnrollmentLoadStatus.success,
      summaries: const [draftRow],
      summariesTotalElements: 1,
      summariesTotalPages: 1,
    );
    when(() => listBloc.state).thenReturn(listState);
    when(
      () => listBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentLocalListState>.empty());

    academicYearBloc = _MockAcademicYearBloc();
    final academicYearState = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(
          id: 'ay-current',
          name: '2026-2027',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2027, 7, 1),
          current: true,
        ),
        schoolLevelGroups: const [],
      ),
      errorMessage: null,
    );
    when(() => academicYearBloc.state).thenReturn(academicYearState);
    when(
      () => academicYearBloc.stream,
    ).thenAnswer((_) => const Stream<AcademicYearContextState>.empty());

    authBloc = _MockAuthBloc();
    const authState = AuthState(
      status: AuthStatus.authenticated,
      user: AuthenticatedUser(
        email: 'a@b.c',
        firstName: 'A',
        lastName: 'B',
        role: 'ADMIN',
        schoolId: 'school-1',
      ),
    );
    when(() => authBloc.state).thenReturn(authState);
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
  });

  testWidgets(
    'retour du détail → la liste locale est re-lue (LocalListRefreshRequested)',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(
            path: '/list',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<EnrollmentLocalListBloc>.value(value: listBloc),
                BlocProvider<AcademicYearContextBloc>.value(
                  value: academicYearBloc,
                ),
                BlocProvider<AuthBloc>.value(value: authBloc),
              ],
              child: const FirstRegistrationPage(),
            ),
          ),
          GoRoute(
            path: '${EnrollmentConstants.enrollmentDetailRoute}/:enrollmentId',
            builder: (context, state) => const Scaffold(body: Text('WIZARD')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      // Ouvre le dossier depuis la ligne (chemin réel : `push`).
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('WIZARD'), findsOneWidget);

      clearInteractions(listBloc);

      // Retour au listing (dépilage : ce que fait la sortie du wizard).
      router.pop();
      await tester.pumpAndSettle();

      final refreshed = verify(
        () => listBloc.add(captureAny()),
      ).captured.whereType<LocalListRefreshRequested>();
      expect(
        refreshed,
        isNotEmpty,
        reason:
            'sans onDetailReturned, la liste garde son état d\'avant le wizard',
      );
    },
  );
}
