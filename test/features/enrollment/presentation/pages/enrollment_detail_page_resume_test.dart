import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couvre l'ORCHESTRATION PAGE de la **reprise d'un brouillon LOCAL**
/// (`localDraftResume`, ouvert depuis le listing) : au montage, la page charge
/// l'agrégat déjà en base par id (`LoadDraftDetailRequested`) — SANS seed
/// (serveur ni cohorte/préinscription) et sans GET online voué à 404.
class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockCurrentYearBloc extends Mock implements AcademicYearContextBloc {}

class _MockPreviousYearBloc extends Mock
    implements AcademicYearPreviousContextBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const LoadDraftDetailRequested('x'));
  });

  late _MockOfflineBloc offlineBloc;
  late _MockEnrollmentBloc enrollmentBloc;
  late _MockCurrentYearBloc currentYearBloc;
  late _MockPreviousYearBloc previousYearBloc;
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
    'localDraftResume → charge le brouillon local par id (LoadDraftDetailRequested)',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.localDraftResume(
          enrollmentId: 'draft-1',
          studentId: 'stu-1',
        ),
      );
      await tester.pump();

      verify(
        () => offlineBloc.add(const LoadDraftDetailRequested('draft-1')),
      ).called(1);
    },
  );

  testWidgets(
    'localDraftResume → AUCUN seed (serveur ni cohorte/préinscription)',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent.localDraftResume(enrollmentId: 'draft-1'),
      );
      await tester.pump();

      // Le brouillon existe déjà en base : ni photographie serveur, ni seed local.
      verifyNever(() => offlineBloc.add(any(that: isA<SeedDraftRequested>())));
      verifyNever(
        () => offlineBloc.add(any(that: isA<SeedFromCohortRequested>())),
      );
      verifyNever(
        () => offlineBloc.add(any(that: isA<SeedFromPreEnrollmentRequested>())),
      );
      // Un NEW vierge démarrerait un brouillon (StartDraftRequested) : pas ici.
      verifyNever(() => offlineBloc.add(any(that: isA<StartDraftRequested>())));
    },
  );
}
