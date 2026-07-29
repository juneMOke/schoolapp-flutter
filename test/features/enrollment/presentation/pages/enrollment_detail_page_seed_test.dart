import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couvre l'ORCHESTRATION PAGE du seed RE/PRE depuis le local (le reste de la
/// chaîne est testé côté bloc/repo/dao/builder) : aiguillage RE→cohorte /
/// PRE→préinscription, année cible = bootstrap COURANT, et l'écran d'erreur +
/// bouton « Réessayer » quand le seed échoue (cohorte/snapshot vides).
class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockCurrentYearBloc extends Mock implements AcademicYearContextBloc {}

class _MockPreviousYearBloc extends Mock
    implements AcademicYearPreviousContextBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const SeedFromCohortRequested(studentId: 'x', academicYearId: 'x'),
    );
  });

  late _MockOfflineBloc offlineBloc;
  late _MockEnrollmentBloc enrollmentBloc;
  late _MockCurrentYearBloc currentYearBloc;
  late _MockPreviousYearBloc previousYearBloc;
  late StreamController<EnrollmentOfflineState> offlineStates;
  late EnrollmentOfflineState offlineState;

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

  AcademicYearContextState currentYearLoaded() => AcademicYearContextState(
    status: AcademicYearContextLoadStatus.success,
    context: currentAcademicYearContext,
    errorMessage: null,
  );

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    enrollmentBloc = _MockEnrollmentBloc();
    currentYearBloc = _MockCurrentYearBloc();
    previousYearBloc = _MockPreviousYearBloc();
    offlineStates = StreamController<EnrollmentOfflineState>.broadcast();
    offlineState = const EnrollmentOfflineInitial();

    when(() => offlineBloc.state).thenAnswer((_) => offlineState);
    when(() => offlineBloc.stream).thenAnswer((_) => offlineStates.stream);
    when(() => offlineBloc.close()).thenAnswer((_) async {});

    when(
      () => enrollmentBloc.state,
    ).thenReturn(const EnrollmentState.initial());
    when(
      () => enrollmentBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentState>.empty());
    when(() => enrollmentBloc.close()).thenAnswer((_) async {});

    when(() => currentYearBloc.state).thenReturn(currentYearLoaded());
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
  });

  tearDown(() => offlineStates.close());

  Future<void> pumpPage(WidgetTester tester, EnrollmentDetailIntent intent) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<EnrollmentOfflineBloc>.value(value: offlineBloc),
            BlocProvider<EnrollmentBloc>.value(value: enrollmentBloc),
            BlocProvider<AcademicYearContextBloc>.value(value: currentYearBloc),
            BlocProvider<AcademicYearPreviousContextBloc>.value(
              value: previousYearBloc,
            ),
          ],
          child: EnrollmentDetailPage(intent: intent),
        ),
      ),
    );
  }

  testWidgets(
    'RE → seede la COHORTE avec studentId de l\'intent + année COURANTE',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'e-re',
          studentId: 'stu-1',
        ),
      );
      await tester.pump(); // exécute le callback post-frame (dispatch du seed)

      verify(
        () => offlineBloc.add(
          const SeedFromCohortRequested(
            studentId: 'stu-1',
            academicYearId: 'ay-current',
          ),
        ),
      ).called(1);
      // Jamais l'événement PRE, jamais l'année d'une autre source.
      verifyNever(
        () => offlineBloc.add(any(that: isA<SeedFromPreEnrollmentRequested>())),
      );
    },
  );

  testWidgets(
    'PRE → seede la PRÉINSCRIPTION avec l\'id de l\'intent + année COURANTE',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.preRegistration(enrollmentId: 'pre-9'),
      );
      await tester.pump();

      verify(
        () => offlineBloc.add(
          const SeedFromPreEnrollmentRequested(
            preEnrollmentId: 'pre-9',
            academicYearId: 'ay-current',
          ),
        ),
      ).called(1);
      verifyNever(
        () => offlineBloc.add(any(that: isA<SeedFromCohortRequested>())),
      );
    },
  );

  testWidgets(
    'PRE (candidat brut, forme réelle produite par PreRegistrationsPage) → '
    'le preEnrollmentId est lu depuis `studentId`, PAS `enrollmentId` (qui '
    'vaut `new` tant qu\'aucun dossier n\'existe) — régression du bug de '
    'round-trip GoRouter',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.preRegistration(
          enrollmentId: 'new',
          studentId: 'pre-9',
        ),
      );
      await tester.pump();

      verify(
        () => offlineBloc.add(
          const SeedFromPreEnrollmentRequested(
            preEnrollmentId: 'pre-9',
            academicYearId: 'ay-current',
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'seed en échec (cohorte vide) → écran d\'erreur + « Réessayer » redispatch le seed',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'e-re',
          studentId: 'stu-1',
        ),
      );
      await tester.pump(); // 1er dispatch (post-frame)

      // Le seed échoue (cohorte non peuplée, pull dormant).
      offlineState = const EnrollmentDraftError(
        'Dossier introuvable en local.',
      );
      offlineStates.add(offlineState);
      await tester.pump();

      // Écran d'erreur avec bouton Réessayer.
      final retry = find.byType(ElevatedButton);
      expect(retry, findsOneWidget);

      await tester.tap(retry);
      await tester.pump();

      // Réessayer a bien re-dispatché le seed (garde _seededIntent remise à
      // zéro) → 2 dispatches au total.
      verify(
        () => offlineBloc.add(
          const SeedFromCohortRequested(
            studentId: 'stu-1',
            academicYearId: 'ay-current',
          ),
        ),
      ).called(2);
    },
  );

  testWidgets(
    'sonde au tap : dossier existant DRAFT → LoadDraftDetailRequested (reprise), '
    'pas de doublon',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'e-re',
          studentId: 'stu-1',
        ),
      );
      await tester
          .pump(); // 1er dispatch = SeedFromCohortRequested (sonde bloc)

      // Le bloc a sondé et trouvé un BROUILLON existant pour cet élève.
      offlineState = const EnrollmentLocalDossierExisting(
        'e-existing',
        SyncState.draft,
      );
      offlineStates.add(offlineState);
      await tester.pump();

      // La page ouvre le brouillon (reprise éditable), jamais un nouveau seed.
      verify(
        () => offlineBloc.add(const LoadDraftDetailRequested('e-existing')),
      ).called(1);
      verifyNever(
        () => offlineBloc.add(any(that: isA<LoadLocalEnrollmentDetail>())),
      );
    },
  );

  testWidgets(
    'sonde au tap : dossier existant FINALISÉ → LoadLocalEnrollmentDetail '
    '(lecture seule)',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'e-re',
          studentId: 'stu-1',
        ),
      );
      await tester.pump();

      // Dossier FINALISÉ (PENDING_SYNC) → option b : lecture seule.
      offlineState = const EnrollmentLocalDossierExisting(
        'e-existing',
        SyncState.pendingSync,
      );
      offlineStates.add(offlineState);
      await tester.pump();

      verify(
        () => offlineBloc.add(const LoadLocalEnrollmentDetail('e-existing')),
      ).called(1);
      verifyNever(
        () => offlineBloc.add(any(that: isA<LoadDraftDetailRequested>())),
      );
    },
  );
}
