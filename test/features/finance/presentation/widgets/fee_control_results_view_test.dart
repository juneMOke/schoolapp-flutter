import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_results_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/fee_control_results_empty_state.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockFeeControlBloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Ce que la session détient. `null` = ensemble jamais communiqué ; l'absence
/// d'instance = aucun `AuthBloc` dans l'arbre. Les deux valent « inconnu ».
class _Session {
  const _Session(this.permissions);
  const _Session.unknown() : permissions = null;

  final List<String>? permissions;
}

/// Le contrôle des frais s'ouvre sur `finance.*` — mais ses lignes viennent du
/// flux Inscription, et sa maille « classe » du flux Classe.
const _sansRien = _Session(['finance.charge.read']);
const _sansClasse = _Session(['finance.charge.read', 'enrollment.read']);
const _complet = _Session([
  'finance.charge.read',
  'enrollment.read',
  'classroom.read',
]);

const tQuery = FeeControlQuery(
  academicYearId: 'ay-1',
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'l1',
  feeCode: 'TUITION',
  statusFilter: FeeControlPaymentFilter.settled,
  firstName: '',
  lastName: '',
  surname: '',
  page: 0,
  size: 10,
);

/// Même recherche, mais bornée à une classe.
const tClassroomQuery = FeeControlQuery(
  academicYearId: 'ay-1',
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'l1',
  classroomId: 'cls-1',
  feeCode: 'TUITION',
  statusFilter: FeeControlPaymentFilter.settled,
  firstName: '',
  lastName: '',
  surname: '',
  page: 0,
  size: 10,
);

/// La même recherche relancée sur un autre statut. Rien de ce qui décide du
/// message de vide ne change (ni la maille, ni le périmètre, ni la
/// répartition) : seule la puce de critère bouge. Une différence dans le
/// message ne peut donc venir que du verdict de droits.
const tRelanceQuery = FeeControlQuery(
  academicYearId: 'ay-1',
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'l1',
  feeCode: 'TUITION',
  statusFilter: FeeControlPaymentFilter.none,
  firstName: '',
  lastName: '',
  surname: '',
  page: 0,
  size: 10,
);

const tRow = FeeControlRow(
  summary: EnrollmentSummary(
    enrollmentId: 'enr-1',
    enrollmentCode: 'code-1',
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
  ),
  aggregate: LocalFeeChargeAggregate(
    studentId: 's1',
    expectedInCents: 150000,
    paidMirrorInCents: 150000,
    paidPendingInCents: 0,
    currency: 'USD',
  ),
);

/// [session] omise = pas d'`AuthBloc` du tout : c'est le cas de tous les tests
/// historiques de ce fichier, et il vaut « droits inconnus ».
Future<void> _pumpView(
  WidgetTester tester,
  FeeControlState state, {
  _Session? session,
}) async {
  final bloc = MockFeeControlBloc();
  when(() => bloc.state).thenReturn(state);
  whenListen(bloc, const Stream<FeeControlState>.empty(), initialState: state);

  Widget child = BlocProvider<FeeControlBloc>.value(
    value: bloc,
    child: AppPageBackground(
      child: FeeControlResultsView(onViewRequested: (_) {}),
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
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('aucune recherche → carte d\'invitation', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(tester, const FeeControlState.initial());

    expect(find.byType(FeeControlSearchInvitationCard), findsOneWidget);
  });

  testWidgets('résultats → tableau', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        rows: [tRow],
        totalElements: 1,
        totalPages: 1,
        studentsInScope: 1,
        breakdown: FeeControlBreakdown(settled: 1),
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(FeeControlDataTable), findsOneWidget);
    expect(find.text('MOKE'), findsOneWidget);
  });

  testWidgets('classe peuplée mais sans créance de ce frais → message dédié', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(),
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(FeeControlResultsEmptyState), findsOneWidget);
    expect(
      find.textContaining('ne porte ce frais'),
      findsOneWidget,
      reason: 'ne pas confondre grille incomplète et critère trop étroit',
    );
  });

  testWidgets('personne ne correspond au statut → message générique', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(settled: 12),
        lastQuery: tQuery,
      ),
    );

    expect(find.textContaining('ne porte ce frais'), findsNothing);
    expect(
      find.textContaining('Aucun élève ne correspond à ces critères'),
      findsOneWidget,
    );
    // Les puces rappellent le frais et le statut demandés, avec les libellés
    // du détail Facturation (code de frais localisé, statut de créance).
    expect(find.text('Frais : Frais de scolarité'), findsOneWidget);
    expect(find.text('Statut : Payé'), findsOneWidget);
  });

  testWidgets('classe choisie, roster local absent → invite à synchroniser', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 0,
        classroomRosterSize: 0,
        lastQuery: tClassroomQuery,
      ),
    );

    expect(
      find.textContaining('n\'est pas encore descendue sur cet appareil'),
      findsOneWidget,
    );
  });

  testWidgets('roster connu mais aucun dossier local → message distinct', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 0,
        classroomRosterSize: 24,
        lastQuery: tClassroomQuery,
      ),
    );

    expect(
      find.textContaining('n\'a de dossier d\'inscription local'),
      findsOneWidget,
    );
    expect(find.textContaining('n\'est pas encore descendue'), findsNothing);
  });

  testWidgets(
    'classe choisie et peuplée mais sans créance → message « ne porte pas ce '
    'frais », pas un message de synchro',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(
        tester,
        const FeeControlState(
          status: EnrollmentLoadStatus.success,
          studentsInScope: 24,
          classroomRosterSize: 24,
          breakdown: FeeControlBreakdown(),
          lastQuery: tClassroomQuery,
        ),
      );

      expect(find.textContaining('ne porte ce frais'), findsOneWidget);
    },
  );

  // B-4 — les trois messages écrits jusqu'ici disaient tous « de cette
  // classe ». Une recherche « toutes les classes du niveau » ne pouvait donc
  // qu'échouer vers « modifiez le formulaire et relancez » : on envoyait
  // l'opérateur corriger des critères qui n'y peuvent rien, alors que sa
  // tablette n'avait simplement aucune inscription pour ce niveau.
  group('maille NIVEAU : le vide a ses propres causes', () {
    testWidgets('aucune inscription locale → le dit, sans accuser la saisie', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(
        tester,
        const FeeControlState(
          status: EnrollmentLoadStatus.success,
          studentsInScope: 0,
          // Aucune classe choisie : `classroomRosterSize` reste nul, et c'est
          // précisément ce qui rendait l'état inatteignable.
          lastQuery: tQuery,
        ),
      );

      expect(
        find.textContaining('Aucun élève inscrit à ce niveau'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Modifiez le formulaire'),
        findsNothing,
        reason: 'les critères n\'y sont pour rien',
      );
    });

    testWidgets('des élèves mais aucun ne porte ce frais → le dit AU NIVEAU', (
      tester,
    ) async {
      // Le message de classe (« de cette classe ») affirmait une maille que
      // l'opérateur n'avait pas choisie.
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(
        tester,
        const FeeControlState(
          status: EnrollmentLoadStatus.success,
          studentsInScope: 30,
          breakdown: FeeControlBreakdown(),
          lastQuery: tQuery,
        ),
      );

      expect(find.textContaining('Aucun élève de ce niveau'), findsOneWidget);
      expect(find.textContaining('de cette classe'), findsNothing);
    });

    testWidgets('CONTRE-ÉPREUVE : des élèves concernés → là, c\'est la saisie', (
      tester,
    ) async {
      // Le seul cas où « modifiez le formulaire » est un bon conseil : des
      // élèves portent bien ce frais, et c'est le filtre de statut ou les noms
      // qui n'ont rien laissé passer. Le décompte est mesuré AVANT le filtre.
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(
        tester,
        const FeeControlState(
          status: EnrollmentLoadStatus.success,
          studentsInScope: 30,
          breakdown: FeeControlBreakdown(settled: 12),
          lastQuery: tQuery,
        ),
      );

      expect(find.textContaining('Modifiez le formulaire'), findsOneWidget);
    });
  });

  testWidgets('échec → écran d\'erreur partagé', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.failure,
        errorType: EnrollmentErrorType.server,
        errorMessage: 'base illisible',
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(EnrollmentResultsErrorState), findsOneWidget);
  });

  // ADR-015 F1c — ce module s'ouvre sur `finance.*`, mais toutes ses lignes
  // viennent du flux Inscription, sauté à chaque cycle de pull faute de
  // `enrollment.read`. Les messages de synchronisation promettent alors une
  // mise à jour qui n'arrivera jamais.
  group('le vide vient d\'un droit, pas d\'une synchro', () {
    /// Roster absent ET droit absent : les deux causes candidates sont vraies
    /// en même temps. C'est le cas qui verrouille l'ORDRE des branches.
    const rosterEtDroitAbsents = FeeControlState(
      status: EnrollmentLoadStatus.success,
      studentsInScope: 0,
      classroomRosterSize: 0,
      lastQuery: tClassroomQuery,
    );

    testWidgets(
      'sans enrollment.read, le droit prime sur « roster non descendu »',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpView(tester, rosterEtDroitAbsents, session: _sansRien);

        expect(
          find.textContaining('le contrôle ne peut porter sur personne'),
          findsOneWidget,
        );
        expect(
          find.textContaining('n\'est pas encore descendue sur cet appareil'),
          findsNothing,
          reason:
              'placée après, la branche de droit ne se déclencherait '
              'jamais : le roster manquant la préempterait et enverrait '
              'attendre un pull qui a déjà eu lieu et qui a sauté ce flux',
        );
      },
    );

    testWidgets(
      'sans enrollment.read, le droit prime aussi sur « aucun dossier local »',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpView(
          tester,
          const FeeControlState(
            status: EnrollmentLoadStatus.success,
            studentsInScope: 0,
            classroomRosterSize: 24,
            lastQuery: tClassroomQuery,
          ),
          session: _sansRien,
        );

        expect(
          find.textContaining('le contrôle ne peut porter sur personne'),
          findsOneWidget,
        );
        expect(
          find.textContaining('n\'a de dossier d\'inscription local'),
          findsNothing,
        );
      },
    );

    testWidgets('sans classroom.read, la recherche par classe le dit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(tester, rosterEtDroitAbsents, session: _sansClasse);

      expect(
        find.textContaining('le contrôle par classe est impossible'),
        findsOneWidget,
      );
      expect(
        find.textContaining('n\'est pas encore descendue sur cet appareil'),
        findsNothing,
      );
    });

    // Le droit sur les classes n'explique un vide que si la requête filtre par
    // classe : à la maille niveau, il n'a rien à voir avec le résultat.
    testWidgets(
      'sans classroom.read mais sans filtre de classe : rien à dire',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpView(
          tester,
          const FeeControlState(
            status: EnrollmentLoadStatus.success,
            studentsInScope: 12,
            breakdown: FeeControlBreakdown(settled: 12),
            lastQuery: tQuery,
          ),
          session: _sansClasse,
        );

        expect(
          find.textContaining('le contrôle par classe est impossible'),
          findsNothing,
        );
        expect(
          find.textContaining('Aucun élève ne correspond à ces critères'),
          findsOneWidget,
        );
      },
    );

    testWidgets('droits complets : les messages de synchro reviennent', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(tester, rosterEtDroitAbsents, session: _complet);

      expect(
        find.textContaining('n\'est pas encore descendue sur cet appareil'),
        findsOneWidget,
      );
      expect(
        find.textContaining('le contrôle ne peut porter sur personne'),
        findsNothing,
      );
    });

    // LE PIÈGE : `canAccess` refuse sur un ensemble `null`, mais un parc de
    // sessions ouvertes avant la migration est ENTIÈREMENT en `null` — ces
    // comptes ont tous les droits et leurs données descendent normalement. Les
    // accuser transformerait un message faux en un message pire.
    testWidgets(
      'droits inconnus (null) → l\'ancien message, jamais l\'accusation',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpView(
          tester,
          rosterEtDroitAbsents,
          session: const _Session.unknown(),
        );

        expect(
          find.textContaining('n\'est pas encore descendue sur cet appareil'),
          findsOneWidget,
        );
        expect(
          find.textContaining('le contrôle ne peut porter sur personne'),
          findsNothing,
        );
        expect(
          find.textContaining('le contrôle par classe est impossible'),
          findsNothing,
        );
      },
    );

    testWidgets('sans AuthBloc dans l\'arbre → l\'ancien message aussi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(tester, rosterEtDroitAbsents);

      expect(
        find.textContaining('n\'est pas encore descendue sur cet appareil'),
        findsOneWidget,
      );
      expect(find.textContaining('n\'a pas accès'), findsNothing);
    });

    // Le tableau porte son propre libellé de vide : sans ce relais, la carte
    // dirait la vérité pendant que la table annoncerait encore une
    // non-correspondance.
    testWidgets('le libellé de vide du tableau dit la même chose', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(
        tester,
        // Recherche lancée, résultats pas encore posés : c'est le tableau qui
        // est rendu, avec ses lignes vides.
        const FeeControlState(lastQuery: tClassroomQuery),
        session: _sansRien,
      );

      expect(find.byType(FeeControlDataTable), findsOneWidget);
      expect(
        find.textContaining('le contrôle ne peut porter sur personne'),
        findsOneWidget,
      );
    });

    // Le verdict se lit EN TÊTE du `builder`, pas dans le `build` extérieur.
    // Depuis le `build`, il serait capturé par la closure du `BlocBuilder` :
    // le `builder` rejoué ne relirait jamais les droits, et la phrase resterait
    // celle de la première seconde pour toute la vie de l'écran — un droit
    // élargi en séance (ou simplement lu après coup, l'ensemble arrivant en
    // `null` au premier rendu) continuerait d'accuser le compte.
    testWidgets('un droit élargi en séance change la phrase au rebuild suivant', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const vide = FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(settled: 12),
        lastQuery: tQuery,
      );
      const videRelance = FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(settled: 12),
        lastQuery: tRelanceQuery,
      );

      // Un vrai flux piloté par le test : un second `pumpWidget` ne rejouerait
      // pas le `create` d'un provider sur un élément réutilisé, et ne prouverait
      // donc rien.
      final states = StreamController<FeeControlState>.broadcast();
      addTearDown(states.close);
      final bloc = MockFeeControlBloc();
      whenListen(bloc, states.stream, initialState: vide);

      // La vue ne s'abonne PAS à l'`AuthBloc` — c'est documenté et voulu. On
      // pilote donc la session par le getter d'état, exactement comme
      // `permissionHolding` la lit, et c'est bien l'émission du `FeeControlBloc`
      // qui déclenche la reconstruction.
      var permissions = _sansRien.permissions;
      final authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenAnswer(
        (_) => AuthState(
          status: AuthStatus.authenticated,
          permissions: permissions,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BlocProvider<FeeControlBloc>.value(
              value: bloc,
              child: AppPageBackground(
                child: FeeControlResultsView(onViewRequested: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('le contrôle ne peut porter sur personne'),
        findsOneWidget,
      );

      permissions = _complet.permissions;
      states.add(videRelance);
      await tester.pumpAndSettle();

      // Témoin : sans reconstruction effective des résultats, la suite ne
      // prouverait rien.
      expect(
        find.text('Statut : À régler'),
        findsOneWidget,
        reason: 'la puce de critère doit avoir suivi la nouvelle recherche',
      );
      expect(
        find.textContaining('le contrôle ne peut porter sur personne'),
        findsNothing,
        reason: 'le verdict de droits était figé par la closure du BlocBuilder',
      );
      expect(
        find.textContaining('Aucun élève ne correspond à ces critères'),
        findsOneWidget,
      );
    });
  });
}
