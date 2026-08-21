import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_student_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/facturation_results_empty_state.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakeEnrollmentLocalListBloc extends Cubit<EnrollmentLocalListState>
    implements EnrollmentLocalListBloc {
  _FakeEnrollmentLocalListBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Ce que la session détient. `null` = ensemble jamais communiqué ; l'absence
/// d'instance = pas d'`AuthBloc` du tout dans l'arbre. Les deux valent
/// « inconnu », et l'écran doit alors retomber sur son message ordinaire.
class _Session {
  const _Session(this.permissions);
  const _Session.unknown() : permissions = null;

  final List<String>? permissions;
}

/// Un caissier ordinaire : il voit les élèves parce qu'`enrollment.read` lui a
/// été ouvert en plus de ses droits Finance.
const _caissierComplet = _Session([
  'finance.charge.read',
  'finance.payment.read',
  'enrollment.read',
]);

/// Le même poste, sans l'ouverture sur Inscription — le cas qui produisait
/// « aucun élève ne correspond à ces critères » sur une base qui ne descendra
/// jamais.
const _caissierSansInscription = _Session([
  'finance.charge.read',
  'finance.payment.read',
]);

const _summary = EnrollmentSummary(
  enrollmentId: 'enr-1',
  enrollmentCode: 'MAT-001',
  status: 'COMPLETED',
  syncState: SyncState.synced,
  student: StudentSummary(
    id: 's1',
    firstName: 'Debbie',
    lastName: 'MOKE',
    surname: 'Junior',
    dateOfBirth: '2010-01-01',
    gender: Gender.female,
  ),
);

const _query = EnrollmentSummariesQuery(
  type: EnrollmentSummaryQueryType.byAcademicInfo,
  status: '',
  academicYearId: 'ay-1',
  page: 0,
  size: 10,
  lastName: 'Kabongo',
  schoolLevelId: 'l1',
);

/// Fabrique d'état — le constructeur exige tous ses champs, ce qui rendrait
/// chaque cas illisible.
EnrollmentLocalListState _state({
  EnrollmentLoadStatus status = EnrollmentLoadStatus.initial,
  List<EnrollmentSummary> summaries = const <EnrollmentSummary>[],
  EnrollmentSummaryQueryType? queryType =
      EnrollmentSummaryQueryType.byAcademicInfo,
  EnrollmentSummariesQuery? lastQuery = _query,
}) => EnrollmentLocalListState(
  summariesStatus: status,
  summaries: summaries,
  summariesPage: 0,
  summariesSize: AppConstants.enrollmentDefaultPageSize,
  summariesTotalElements: summaries.length,
  summariesTotalPages: summaries.isEmpty ? 0 : 1,
  summariesQueryType: queryType,
  lastSummariesQuery: lastQuery,
  summariesErrorType: null,
  errorMessage: null,
);

Future<void> _pumpTable(
  WidgetTester tester,
  EnrollmentLocalListState state, {
  _Session? session,
}) async {
  tester.view.physicalSize = const Size(1400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Widget child = BlocProvider<EnrollmentLocalListBloc>(
    create: (_) => _FakeEnrollmentLocalListBloc(state),
    child: AppPageBackground(
      child: FacturationStudentTable(onViewRequested: (_, _) {}),
    ),
  );

  if (session != null) {
    final authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: session.permissions,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );
    child = BlocProvider<AuthBloc>.value(value: authBloc, child: child);
  }

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// La phrase qui accuse le profil, réduite à son fragment discriminant.
const _accusation = 'aucun élève ne peut être affiché ici';

/// Le message ordinaire de non-correspondance — celui qui ment quand la table
/// locale est vide faute de droit, et qui reste juste dans tous les autres cas.
const _nonCorrespondance = 'Aucun élève ne correspond à ces critères';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('aucune recherche → carte d\'invitation', (tester) async {
    await _pumpTable(tester, _state(queryType: null, lastQuery: null));

    expect(find.byType(FacturationSearchInvitationCard), findsOneWidget);
  });

  testWidgets('des résultats → tableau, quel que soit le profil', (
    tester,
  ) async {
    await _pumpTable(
      tester,
      _state(status: EnrollmentLoadStatus.success, summaries: const [_summary]),
      session: _caissierComplet,
    );

    expect(find.byType(FacturationDataTable), findsOneWidget);
    expect(find.text('MOKE'), findsOneWidget);
  });

  // ADR-015 F1c — trois états, trois messages. Le vide affirmatif ne doit
  // sortir que lorsqu'on sait qu'il y avait quelque chose à faire correspondre.
  group('carte de vide : la cause du vide', () {
    final vide = _state(status: EnrollmentLoadStatus.success);

    testWidgets('sans enrollment.read → dit le droit, pas les critères', (
      tester,
    ) async {
      await _pumpTable(tester, vide, session: _caissierSansInscription);

      expect(find.byType(FacturationResultsEmptyState), findsOneWidget);
      expect(find.textContaining(_accusation), findsOneWidget);
      expect(
        find.textContaining(_nonCorrespondance),
        findsNothing,
        reason:
            'il n\'y a pas d\'élève à faire correspondre : changer les '
            'critères n\'y changera rien',
      );
    });

    testWidgets('avec enrollment.read → le vide reste une information', (
      tester,
    ) async {
      await _pumpTable(tester, vide, session: _caissierComplet);

      expect(find.textContaining(_nonCorrespondance), findsOneWidget);
      expect(find.textContaining(_accusation), findsNothing);
    });

    // Le piège : `canAccess` refuse sur `null`, donc traiter « inconnu » comme
    // « absent » accuserait tout le parc pré-migration — des comptes qui ont
    // TOUS les droits et dont les données descendent normalement.
    testWidgets(
      'droits inconnus (null) → message générique, pas l\'accusation',
      (tester) async {
        await _pumpTable(tester, vide, session: const _Session.unknown());

        expect(find.textContaining(_nonCorrespondance), findsOneWidget);
        expect(find.textContaining(_accusation), findsNothing);
      },
    );

    testWidgets('sans AuthBloc dans l\'arbre → message générique', (
      tester,
    ) async {
      await _pumpTable(tester, vide);

      expect(find.textContaining(_nonCorrespondance), findsOneWidget);
      expect(find.textContaining(_accusation), findsNothing);
    });

    testWidgets('les puces de critères restent affichées', (tester) async {
      await _pumpTable(tester, vide, session: _caissierSansInscription);

      expect(find.text('Nom: Kabongo'), findsOneWidget);
    });
  });

  // Le tableau porte son propre libellé de vide : sans ce relais, la carte
  // dirait la vérité pendant que la table continuerait d'annoncer une
  // non-correspondance deux pixels plus bas.
  group('libellé de vide du tableau', () {
    final tableauVide = _state();

    testWidgets('sans enrollment.read → la même phrase que la carte', (
      tester,
    ) async {
      await _pumpTable(tester, tableauVide, session: _caissierSansInscription);

      expect(find.byType(FacturationDataTable), findsOneWidget);
      expect(find.textContaining(_accusation), findsOneWidget);
      expect(find.text('Aucun résultat trouvé'), findsNothing);
    });

    testWidgets('avec enrollment.read → le libellé ordinaire', (tester) async {
      await _pumpTable(tester, tableauVide, session: _caissierComplet);

      expect(find.text('Aucun résultat trouvé'), findsOneWidget);
      expect(find.textContaining(_accusation), findsNothing);
    });

    testWidgets('droits inconnus → le libellé ordinaire', (tester) async {
      await _pumpTable(tester, tableauVide, session: const _Session.unknown());

      expect(find.text('Aucun résultat trouvé'), findsOneWidget);
      expect(find.textContaining(_accusation), findsNothing);
    });
  });
}
