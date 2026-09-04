import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/fee_control/presentation/pages/fee_control_dashboard_page.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/states/fee_control_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockDashboardBloc
    extends MockBloc<FeeControlDashboardEvent, FeeControlDashboardState>
    implements FeeControlDashboardBloc {}

/// `MockBloc`, et non `Mock` : un `Mock` nu rend `null` sur `stream` et
/// `close()`, que `BlocProvider` appelle tous deux — l'écran plantait au
/// démontage sur un `Null is not a subtype of Future<void>`.
class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDashboardBloc bloc;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AcademicYearContextRequested());
    registerFallbackValue(const FeeControlDashboardRefreshRequested());
  });

  setUp(() {
    bloc = _MockDashboardBloc();
    academicYearBloc = _MockAcademicYearBloc();
    authBloc = _MockAuthBloc();

    final academicYearState = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(
          id: 'ay-1',
          name: '2026-2027',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2027, 7, 1),
          current: true,
        ),
        schoolLevelGroups: const [],
      ),
    );
    whenListen(
      academicYearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: academicYearState,
    );

    const authState = AuthState(status: AuthStatus.authenticated);
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: authState,
    );

    GetIt.instance.registerFactory<FeeControlDashboardBloc>(() => bloc);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pump(WidgetTester tester, FeeControlDashboardState state) async {
    // ⚠️ Le bloc part de `initial` et TRANSITE vers [state] : c'est le
    // changement que la page écoute pour s'auto-sélectionner. Lui donner
    // directement l'état final ferait passer le test à côté de tout —
    // `listenWhen` compare l'ancien et le nouveau, et ne verrait rien bouger.
    // C'est fidèle à la production : la page reçoit un bloc NEUF à chaque
    // montage (`registerFactory`), donc toujours à `initial`.
    whenListen(
      bloc,
      Stream<FeeControlDashboardState>.value(state),
      initialState: const FeeControlDashboardState.initial(),
    );

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AcademicYearContextBloc>.value(
              value: academicYearBloc,
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const FeeControlDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('à l\'ouverture, l\'écran DEMANDE la liste des natures — sans '
      'quoi il reste inerte sur un grand-livre plein', (tester) async {
    // ⚠️ Personne ne la demandait : l'écran écoutait `feeCodes` sans que rien
    // n'émette jamais l'événement qui les charge. Le sélecteur restait vide et
    // désactivé, l'auto-sélection n'avait aucune liste sur quoi s'ouvrir, et le
    // tableau de bord n'affichait rien — sans la moindre erreur. Les autres
    // tests de ce fichier partaient d'un état où les natures étaient DÉJÀ là :
    // ils ne pouvaient pas le voir.
    await pump(tester, const FeeControlDashboardState.initial());

    verify(
      () => bloc.add(
        const FeeControlDashboardFeeCodesRequested(academicYearId: 'ay-1'),
      ),
    ).called(1);
  });

  testWidgets('la lecture des natures en ÉCHEC se dit, et offre la reprise', (
    tester,
  ) async {
    // Le même vide que « aucune créance sur l'appareil », pour une raison très
    // différente. Se taire enverrait synchroniser un appareil qui n'a rien à
    // synchroniser.
    await pump(
      tester,
      const FeeControlDashboardState(
        feeCodesStatus: EnrollmentLoadStatus.failure,
        errorType: EnrollmentErrorType.server,
      ),
    );

    expect(find.byType(EnrollmentResultsErrorState), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    // Deux fois : l'amorçage au montage, puis la reprise.
    verify(
      () => bloc.add(
        const FeeControlDashboardFeeCodesRequested(academicYearId: 'ay-1'),
      ),
    ).called(2);
  });

  testWidgets('à l\'ouverture, l\'écran interroge de lui-même le frais le PLUS '
      'PORTÉ — le premier que le grand-livre rend', (tester) async {
    await pump(
      tester,
      const FeeControlDashboardState(
        feeCodesStatus: EnrollmentLoadStatus.success,
        // Le DAO les trie par effectif décroissant : TUITION est le plus porté,
        // CANTINE marginal. Un tri alphabétique aurait ouvert sur CANTINE.
        feeCodes: ['TUITION', 'CANTINE'],
      ),
    );

    final captured = verify(
      () => bloc.add(captureAny(that: isA<FeeControlDashboardRequested>())),
    ).captured.cast<FeeControlDashboardRequested>();

    expect(captured, isNotEmpty);
    expect(captured.first.feeCode, 'TUITION');
    expect(captured.first.academicYearId, 'ay-1');
    // Aucun cycle : le tableau ouvre sur TOUTE l'école.
    expect(captured.first.schoolLevelGroupId, isNull);
  });

  testWidgets('aucune créance sur l\'appareil : l\'écran le DIT, au lieu '
      'd\'offrir deux champs inertes', (tester) async {
    await pump(
      tester,
      const FeeControlDashboardState(
        feeCodesStatus: EnrollmentLoadStatus.success,
        feeCodes: <String>[],
      ),
    );

    expect(find.byType(FeeControlDashboardEmptyState), findsOneWidget);
    expect(find.text('Aucun frais facturé'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<FeeControlDashboardRequested>())));
  });
}
