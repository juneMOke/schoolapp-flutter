import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Garde de SORTIE du wizard (popin de confirmation d'abandon) :
///  - brouillon matérialisé → back système ET boutons app bar passent par la
///    popin ; refus → on reste ; confirmation → retour listing Première
///    inscription (fallback `goNamed` avec `subMenuId`) ;
///  - brouillon NON matérialisé (spinner d'amorce) → aucune popin.
class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockCurrentYearBloc extends Mock implements AcademicYearContextBloc {}

class _MockPreviousYearBloc extends Mock
    implements AcademicYearPreviousContextBloc {}

class _MockStudentBloc extends Mock implements StudentBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const LoadDraftDetailRequested('x'));
  });

  late _MockOfflineBloc offlineBloc;
  late _MockEnrollmentBloc enrollmentBloc;
  late _MockCurrentYearBloc currentYearBloc;
  late _MockPreviousYearBloc previousYearBloc;
  late _MockStudentBloc studentBloc;
  late StreamController<EnrollmentOfflineState> offlineStates;

  final currentAcademicYearContext = AcademicYearContext(
    academicYear: AcademicYear(
      id: 'ay-current',
      name: '2026-2027',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2027, 7, 1),
      current: true,
    ),
    schoolLevelGroups: const [],
  );

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    enrollmentBloc = _MockEnrollmentBloc();
    currentYearBloc = _MockCurrentYearBloc();
    previousYearBloc = _MockPreviousYearBloc();
    studentBloc = _MockStudentBloc();
    offlineStates = StreamController<EnrollmentOfflineState>.broadcast();

    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());
    when(() => offlineBloc.stream).thenAnswer((_) => offlineStates.stream);
    when(() => offlineBloc.close()).thenAnswer((_) async {});

    when(
      () => enrollmentBloc.state,
    ).thenReturn(const EnrollmentState.initial());
    when(
      () => enrollmentBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentState>.empty());
    when(() => enrollmentBloc.close()).thenAnswer((_) async {});

    when(() => currentYearBloc.state).thenReturn(
      AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: currentAcademicYearContext,
        errorMessage: null,
      ),
    );
    when(
      () => currentYearBloc.stream,
    ).thenAnswer((_) => const Stream<AcademicYearContextState>.empty());
    when(() => currentYearBloc.close()).thenAnswer((_) async {});

    when(
      () => previousYearBloc.state,
    ).thenReturn(const AcademicYearPreviousContextState.initial());
    when(
      () => previousYearBloc.stream,
    ).thenAnswer((_) => const Stream<AcademicYearPreviousContextState>.empty());
    when(() => previousYearBloc.close()).thenAnswer((_) async {});

    when(
      () => studentBloc.stream,
    ).thenAnswer((_) => const Stream<StudentState>.empty());
    when(() => studentBloc.state).thenReturn(const StudentState.initial());
    when(() => studentBloc.close()).thenAnswer((_) async {});
    getIt.registerFactory<StudentBloc>(() => studentBloc);
  });

  tearDown(() async {
    await offlineStates.close();
    await getIt.reset();
  });

  Future<void> pumpWizard(
    WidgetTester tester,
    EnrollmentDetailIntent intent,
  ) async {
    // Cible produit = tablette paysage : la surface par défaut (800×600) fait
    // déborder la barre d'actions du stepper (bruit de layout hors sujet).
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/wizard',
      routes: [
        GoRoute(
          path: '/',
          name: AppRoutesNames.home,
          builder: (context, state) => Scaffold(
            body: Text('HOME:${state.uri.queryParameters['subMenuId'] ?? ''}'),
          ),
        ),
        GoRoute(
          path: '/wizard',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<EnrollmentOfflineBloc>.value(value: offlineBloc),
              BlocProvider<EnrollmentBloc>.value(value: enrollmentBloc),
              BlocProvider<AcademicYearContextBloc>.value(
                value: currentYearBloc,
              ),
              BlocProvider<AcademicYearPreviousContextBloc>.value(
                value: previousYearBloc,
              ),
            ],
            child: EnrollmentDetailPage(intent: intent),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    );
    await tester.pump();
  }

  /// Matérialise le brouillon NEW : la page a dispatché StartDraftRequested,
  /// on lui répond les ids client → l'agrégat vierge se compose (bootstrap OK)
  /// et le stepper s'affiche.
  Future<void> materializeNewDraft(WidgetTester tester) async {
    offlineStates.add(const EnrollmentDraftStarted('enr-1', 'stu-1'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'back système sur un brouillon matérialisé → popin ; refus → on reste',
    (tester) async {
      await pumpWizard(
        tester,
        const EnrollmentDetailIntent.newFirstRegistration().withEnrollmentId(
          'new',
        ),
      );
      await materializeNewDraft(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Quitter l\'inscription ?'), findsOneWidget);

      await tester.tap(find.text('Continuer la saisie'));
      await tester.pumpAndSettle();
      expect(find.text('Quitter l\'inscription ?'), findsNothing);
      expect(find.textContaining('HOME:'), findsNothing);
    },
  );

  testWidgets(
    'fermeture app bar confirmée → retour au listing Première inscription '
    '(subMenuId porté par le goNamed)',
    (tester) async {
      await pumpWizard(
        tester,
        const EnrollmentDetailIntent.newFirstRegistration().withEnrollmentId(
          'new',
        ),
      );
      await materializeNewDraft(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Quitter l\'inscription ?'), findsOneWidget);

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      // MenuConstants.premiereInscriptionId — asserté par le suffixe non vide.
      final home = tester.widget<Text>(find.textContaining('HOME:'));
      expect(home.data, isNot('HOME:'));
    },
  );

  testWidgets(
    'brouillon NON matérialisé (spinner d\'amorce) → sortie libre, aucune popin',
    (tester) async {
      await pumpWizard(
        tester,
        const EnrollmentDetailIntent.localDraftResume(enrollmentId: 'draft-1'),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Quitter l\'inscription ?'), findsNothing);
      expect(find.textContaining('HOME:'), findsOneWidget);
    },
  );
}
