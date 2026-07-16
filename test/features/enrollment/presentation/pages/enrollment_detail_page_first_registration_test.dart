import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_academic_year.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couvre l'ORCHESTRATION PAGE de la **Première inscription** : consultation
/// LECTURE SEULE servie depuis le local — la page sonde l'agrégat local
/// (`LoadLocalEnrollmentDetail`) et ne dispatche JAMAIS de GET serveur
/// (`EnrollmentBloc`) ; un dossier introuvable en local remonte l'écran
/// d'erreur dont « Réessayer » re-sonde.
class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockCurrentYearBloc extends Mock implements BootstrapCurrentYearBloc {}

class _MockPreviousYearBloc extends Mock implements BootstrapPreviousYearBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const LoadLocalEnrollmentDetail('x'));
    registerFallbackValue(const EnrollmentSummariesRefreshRequested());
  });

  late _MockOfflineBloc offlineBloc;
  late _MockEnrollmentBloc enrollmentBloc;
  late _MockCurrentYearBloc currentYearBloc;
  late _MockPreviousYearBloc previousYearBloc;
  late StreamController<EnrollmentOfflineState> offlineStates;
  late EnrollmentOfflineState offlineState;

  final currentBootstrap = Bootstrap(
    schoolId: 'sch-1',
    academicYear: BootstrapAcademicYear(
      id: 'ay-current',
      name: '2026-2027',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2027, 7, 1),
      current: true,
    ),
    schoolLevelGroups: const [],
  );

  BootstrapContextState currentYearLoaded() => BootstrapContextState(
    status: BootstrapContextLoadStatus.success,
    bootstrap: currentBootstrap,
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
    ).thenAnswer((_) => const Stream<BootstrapContextState>.empty());
    when(() => currentYearBloc.close()).thenAnswer((_) async {});

    when(
      () => previousYearBloc.state,
    ).thenReturn(const BootstrapContextState.initial());
    when(
      () => previousYearBloc.stream,
    ).thenAnswer((_) => const Stream<BootstrapContextState>.empty());
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
            BlocProvider<BootstrapCurrentYearBloc>.value(
              value: currentYearBloc,
            ),
            BlocProvider<BootstrapPreviousYearBloc>.value(
              value: previousYearBloc,
            ),
          ],
          child: EnrollmentDetailPage(intent: intent),
        ),
      ),
    );
  }

  const inProgressIntent = EnrollmentDetailIntent(
    origin: EnrollmentDetailOrigin.firstRegistration,
    enrollmentId: 'e1',
    status: 'IN_PROGRESS',
  );

  testWidgets(
    'firstRegistration → sonde le local et NE dispatche AUCUN GET serveur',
    (tester) async {
      await pumpPage(tester, inProgressIntent);
      await tester.pump();

      verify(
        () => offlineBloc.add(const LoadLocalEnrollmentDetail('e1')),
      ).called(1);
      // Lecture 100 % locale : le bloc online (GET détail serveur) n'est jamais
      // sollicité — c'est ce qui provoquait le loading infini hors-ligne.
      verifyNever(() => enrollmentBloc.add(any()));
    },
  );

  testWidgets(
    'firstRegistration finalisé (COMPLETED) → sonde locale aussi, jamais de GET',
    (tester) async {
      await pumpPage(
        tester,
        const EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: 'e2',
          status: 'COMPLETED',
        ),
      );
      await tester.pump();

      verify(
        () => offlineBloc.add(const LoadLocalEnrollmentDetail('e2')),
      ).called(1);
      verifyNever(() => enrollmentBloc.add(any()));
    },
  );

  testWidgets(
    'dossier introuvable en local → écran d\'erreur + « Réessayer » re-sonde',
    (tester) async {
      await pumpPage(tester, inProgressIntent);
      await tester.pump(); // 1re sonde

      // La lecture locale échoue (dossier absent / erreur de stockage).
      offlineState = const EnrollmentOfflineError(
        'Dossier introuvable en local',
      );
      offlineStates.add(offlineState);
      await tester.pump();

      final retry = find.byType(ElevatedButton);
      expect(retry, findsOneWidget);

      await tester.tap(retry);
      await tester.pump();

      // « Réessayer » a re-dispatché la lecture locale → 2 sondes au total.
      verify(
        () => offlineBloc.add(const LoadLocalEnrollmentDetail('e1')),
      ).called(2);
      // Toujours aucun repli sur le serveur.
      verifyNever(() => enrollmentBloc.add(any()));
    },
  );
}
