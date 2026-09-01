import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_student.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockCurrentYearBloc extends Mock implements AcademicYearContextBloc {}

class _MockPreviousYearBloc extends Mock
    implements AcademicYearPreviousContextBloc {}

/// Correction d'un dossier **déjà complété** : l'entrée, ce qu'elle écrit (rien
/// tout de suite), et la sortie d'une correction non validée.
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

  final currentContext = AcademicYearContext(
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
    when(() => currentYearBloc.state).thenReturn(
      AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: currentContext,
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
  });

  tearDown(() => offlineStates.close());

  LocalEnrollmentDetail dossier({
    required SyncState syncState,
    OfflineEnrollmentStatus status = OfflineEnrollmentStatus.completed,
  }) => LocalEnrollmentDetail(
    enrollment: LocalEnrollment(
      id: 'e1',
      studentId: 's1',
      enrollmentType: EnrollmentType.newEnrollment,
      status: status,
      academicYearId: 'ay-current',
      enrollmentDate: '2026-07-06',
      syncState: syncState,
    ),
    student: const LocalStudent(
      id: 's1',
      firstName: 'Amina',
      lastName: 'Moke',
      gender: OfflineGender.female,
      dateOfBirth: '2015-04-02',
    ),
  );

  Future<void> ouvrir(WidgetTester tester, LocalEnrollmentDetail local) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Un vrai routeur : la sortie par défaut de l'en-tête en a besoin, et c'est
    // précisément ce chemin qu'emprunte une correction SANS modification.
    final router = GoRouter(
      initialLocation: '/wizard',
      routes: [
        GoRoute(
          path: '/',
          name: AppRoutesNames.home,
          builder: (context, state) => const Scaffold(body: Text('ACCUEIL')),
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
            child: const EnrollmentDetailPage(
              intent: EnrollmentDetailIntent(
                origin: EnrollmentDetailOrigin.firstRegistration,
                enrollmentId: 'e1',
                status: 'COMPLETED',
              ),
            ),
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
    offlineState = EnrollmentOfflineDetailLoaded(local);
    offlineStates.add(offlineState);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Bouton PLEIN du design system, pas un texte posé sur la barre sombre : la
  // seule porte de sortie de la lecture seule doit se voir comme une action.
  Finder modifier() => find.widgetWithText(EteeloButton, 'Modifier');

  testWidgets('un dossier complété propose « Modifier »', (tester) async {
    await ouvrir(tester, dossier(syncState: SyncState.synced));

    expect(modifier(), findsOneWidget);
  });

  /// Sa commande d'outbox est constituée : le rouvrir ferait diverger ce qui
  /// part de ce qui est en base.
  testWidgets('un dossier DÉJÀ dans la file d\'envoi ne le propose pas', (
    tester,
  ) async {
    await ouvrir(tester, dossier(syncState: SyncState.pendingSync));

    expect(modifier(), findsNothing);
  });

  testWidgets('un dossier ANNULÉ ne le propose pas : on en ouvre un autre', (
    tester,
  ) async {
    await ouvrir(
      tester,
      dossier(
        syncState: SyncState.synced,
        status: OfflineEnrollmentStatus.cancelled,
      ),
    );

    expect(modifier(), findsNothing);
  });

  /// Le cœur de la décision « bascule à la 1re modification réelle » : entrer
  /// en correction arme la session et n'écrit RIEN. Un dossier ouvert puis
  /// quitté sans rien changer doit rester facturable.
  testWidgets('entrer en correction arme la session sans rien déclasser', (
    tester,
  ) async {
    await ouvrir(tester, dossier(syncState: SyncState.synced));

    await tester.tap(modifier());
    await tester.pump();

    verify(
      () => offlineBloc.add(const ReeditionSessionStarted('e1')),
    ).called(1);
    // L'action disparaît : on y est.
    expect(modifier(), findsNothing);
  });

  testWidgets('quand la correction est proposée, le bandeau ne dit plus '
      '« non modifiable »', (tester) async {
    await ouvrir(tester, dossier(syncState: SyncState.synced));

    expect(find.textContaining('non modifiable'), findsNothing);
    expect(find.textContaining('corriger'), findsOneWidget);
  });

  /// Sortie d'une correction **non validée**. Ce test couvre deux choses d'un
  /// coup, et c'est voulu : pour que la popin apparaisse, il faut d'abord que
  /// l'écran ait ACCEPTÉ le rechargement du dossier passé en brouillon. Sans
  /// cette porte, la page resterait sur l'agrégat d'avant la correction — le
  /// pire des états, celui qui a l'air enregistré.
  group('sortie d\'une correction non validée', () {
    Future<void> corrigerPuisRecharger(WidgetTester tester) async {
      await ouvrir(tester, dossier(syncState: SyncState.synced));
      await tester.tap(modifier());
      await tester.pump();
      // Ce que fait la première sauvegarde d'étape : le dossier est ré-ouvert
      // en brouillon, et la page relit l'agrégat local.
      offlineState = EnrollmentOfflineDetailLoaded(
        dossier(syncState: SyncState.draft),
      );
      offlineStates.add(offlineState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('quitter prévient que l\'élève sort de la facturation', (
      tester,
    ) async {
      await corrigerPuisRecharger(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Correction non validée'), findsOneWidget);
      expect(find.textContaining('facturation'), findsOneWidget);
    });

    testWidgets('« Reprendre la correction » referme la popin et reste là', (
      tester,
    ) async {
      await corrigerPuisRecharger(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reprendre la correction'));
      await tester.pumpAndSettle();

      expect(find.text('Correction non validée'), findsNothing);
      expect(find.byType(EnrollmentDetailPage), findsOneWidget);
    });

    /// Tant que rien n'est enregistré, le dossier n'est pas déclassé : il n'y a
    /// rien à prévenir, et une popin de plus serait une popin de trop.
    testWidgets('sans modification enregistrée, aucune popin', (tester) async {
      await ouvrir(tester, dossier(syncState: SyncState.synced));
      await tester.tap(modifier());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Correction non validée'), findsNothing);
      expect(find.text('ACCUEIL'), findsOneWidget);
    });
  });
}
