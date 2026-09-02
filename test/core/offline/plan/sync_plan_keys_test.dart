import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../features/offline_full_db.dart';

/// Rien ici ne déclenche de cycle : la DI a seulement besoin d'un service de
/// connectivité résoluble. Le dire « hors ligne » garantit en plus qu'un
/// `pullAll()` accidentel ne partirait sur le réseau.
class _AlwaysOffline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => false;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Le seul moyen honnête d'énumérer les handlers **réellement enregistrés**.
///
/// `PullCoordinator._handlers` est privé et n'a aucun accesseur ; recopier la
/// liste des ressources à la main dériverait avec le code au lieu de le
/// contredire. On substitue donc au coordinateur de production une sous-classe
/// qui note ce que la DI lui passe — et qui note **chaque appel**, pas la Map
/// finale : le registre écrase silencieusement, or c'est exactement l'écrasement
/// que F-I7 doit rendre visible.
class _RecordingPullCoordinator extends PullCoordinator {
  _RecordingPullCoordinator({required super.connectivity});

  final List<PullHandler> registrations = [];

  @override
  void registerHandler(PullHandler handler) {
    registrations.add(handler);
    super.registerHandler(handler);
  }
}

/// Les vingt constantes de [SyncPlanKeys], référencées **par leur symbole**.
///
/// Une liste de chaînes recopiées ne prouverait rien ; ces références-là ne
/// compilent que tant que les constantes existent, et la comparaison
/// ensembliste ci-dessous échoue dès qu'une clé est déclarée sans être câblée
/// dans [kSyncPlanAliases] (ou l'inverse).
const List<String> _kDeclaredPlanKeys = [
  SyncPlanKeys.schoolReferential,
  SyncPlanKeys.enrollmentSnapshots,
  SyncPlanKeys.enrollmentReenrollmentCohort,
  SyncPlanKeys.enrollmentPreEnrollments,
  SyncPlanKeys.classroomClassrooms,
  SyncPlanKeys.classroomMembers,
  SyncPlanKeys.classroomTransfers,
  SyncPlanKeys.financeExchangeRates,
  SyncPlanKeys.financeStudentCharges,
  SyncPlanKeys.financePayments,
  SyncPlanKeys.attendanceRecords,
  SyncPlanKeys.disciplineCases,
  SyncPlanKeys.boutiqueSales,
  SyncPlanKeys.scheduleTimeSlots,
  SyncPlanKeys.scheduleSessions,
  SyncPlanKeys.academicsGradesReferential,
  SyncPlanKeys.academicsCours,
  SyncPlanKeys.academicsEvaluations,
  SyncPlanKeys.academicsNotes,
  SyncPlanKeys.editiqueDocuments,
];

/// Les huit ressources dont la clé de curseur réelle porte un suffixe.
///
/// ⚠️ Déduire cette liste de `mode`/`scope` du plan serait **faux**. Le contrat
/// annonce « FANOUT ⇒ préfixe » ; la règle est incomplète :
///  - `editique.documents` est KEYSET + school et porte pourtant `@<schoolId>`
///    (`'$kEditiqueDocumentsResource@$schoolId'`) ;
///  - `enrollment.reenrollment-cohort` est COHORT + school et porte
///    `:<yearId>` (`'$cohortResource:$currentYearId'`, clé nue en repli) ;
///  - `boutique.sales` est KEYSET + school et porte `@<schoolId>`, pour la même
///    raison que l'éditique : une tablette réaffectée reprendrait sinon au
///    curseur de l'école précédente, et les ventes de la nouvelle ne
///    descendraient jamais.
/// Interroger `sync_meta` sur la ressource nue rendrait `null` pour ces
/// huit-là, et conclure « ce flux n'a jamais été tiré » serait un contresens.
const Set<String> _kSuffixedCursorResources = {
  'academics_cours',
  'academics_evaluations',
  'academics_notes',
  'academics_grades_referential',
  'schedule_sessions',
  'editique_documents',
  'boutique_sales',
  'enrollment_reenrollment_cohort',
};

void main() {
  late Database db;
  late GetIt getIt;
  late _RecordingPullCoordinator coordinator;

  /// Les `PullHandler.resource` que la DI de production enregistre réellement,
  /// dans l'ordre d'enregistrement (= l'ordre d'exécution du coordinateur).
  late List<String> registeredResources;

  setUp(() async {
    db = await openFullOfflineDb();
    getIt = GetIt.asNewInstance();
    coordinator = _RecordingPullCoordinator(connectivity: _AlwaysOffline());

    // Le strict nécessaire pour que les quatre registrars tournent : tout le
    // reste de leur contenu est paresseux et ne sera jamais résolu ici.
    getIt.registerSingleton<Database>(db);
    getIt.registerSingleton<Map<String, dynamic>>(<String, dynamic>{});
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
    getIt.registerSingleton<Dio>(Dio());
    getIt.registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
    getIt.registerSingleton<SyncMetaDao>(SyncMetaDao(db));
    getIt.registerSingleton<OutboxDao>(OutboxDao(db));
    getIt.registerSingleton<AuthLocalDao>(AuthLocalDao(db));
    getIt.registerSingleton<CurrentUserContext>(CurrentUserContext());
    getIt.registerSingleton<ConnectivityService>(_AlwaysOffline());
    getIt.registerSingleton<PullCompletionBus>(PullCompletionBus());
    getIt.registerSingleton<SyncEngine>(
      SyncEngine(
        outbox: getIt<OutboxDao>(),
        connectivity: getIt<ConnectivityService>(),
      ),
    );
    getIt.registerSingleton<PullCoordinator>(coordinator);

    // Le point d'entrée de production, pas une reconstitution : c'est lui qui
    // décide quels flux existent sur cette application.
    registerOfflineModules(getIt);

    registeredResources = [
      for (final handler in coordinator.registrations) handler.resource,
    ];
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  // ── F-I1 — l'invariant, en deux moitiés ───────────────────────────────────
  //
  // Une clé mal orthographiée d'un côté ou de l'autre donne un flux présent au
  // plan et jamais tiré : ni erreur, ni log. Sous F5, où le plan devient
  // l'autorité, ce n'est plus une dégradation mais l'arrêt total de ce flux.

  test('F-I1a : tout handler enregistré est couvert par une clé de plan', () {
    expect(
      registeredResources,
      isNotEmpty,
      reason:
          'Aucun handler recensé : le harnais ne monte plus la DI, et les '
          'assertions qui suivent seraient vertes pour rien.',
    );

    final orphans = registeredResources
        .where((resource) => planKeyOf(resource) == null)
        .toList();

    expect(
      orphans,
      isEmpty,
      reason:
          "Handlers enregistrés qu'aucune planKey ne désigne : $orphans. "
          'Sous F5 ces flux ne seraient plus jamais tirés.',
    );
  });

  test(
    'F-I1b : toute clé de la table couvre au moins un handler enregistré',
    () {
      final registered = registeredResources.toSet();

      final unbacked = <String, List<String>>{};
      for (final entry in kSyncPlanAliases.entries) {
        final covered = entry.value.where(registered.contains).toList();
        if (covered.isEmpty) unbacked[entry.key] = entry.value;
      }

      expect(
        unbacked,
        isEmpty,
        reason:
            'Clés de plan sans aucun handler enregistré : $unbacked. Le serveur '
            'annoncerait un flux que ce client ne sait pas tirer.',
      );
    },
  );

  test('F-I7 : deux handlers ne déclarent jamais la même ressource', () {
    // Le registre est une `Map` : la seconde inscription écrase la première
    // **sans un mot**. Ce test prouve qu'il n'avale rien aujourd'hui — d'où la
    // comparaison sur la liste des appels, jamais sur la Map résultante.
    final owners = <String, int>{};
    for (final resource in registeredResources) {
      owners[resource] = (owners[resource] ?? 0) + 1;
    }
    final duplicated = Map.fromEntries(
      owners.entries.where((entry) => entry.value > 1),
    );

    expect(
      duplicated,
      isEmpty,
      reason:
          'Ressources enregistrées plusieurs fois (la dernière écrase les '
          'précédentes en silence) : $duplicated',
    );
  });

  // ── Le compte : vingt clés, vingt et une ressources ───────────────────────

  test('vingt clés de plan pour vingt et une ressources de handler', () {
    expect(kSyncPlanAliases.length, 20);
    expect(registeredResources.length, 21);

    final aliased = [
      for (final resources in kSyncPlanAliases.values) ...resources,
    ];
    expect(aliased.length, 21);
    // Vingt et une ressources aliasées ET autant de handlers : les deux
    // ensembles coïncident donc exactement (F-I1a + F-I1b + ce compte).
    expect(aliased.toSet(), registeredResources.toSet());
  });

  test('la seule clé qui porte deux ressources est enrollment.snapshots', () {
    final multi = {
      for (final entry in kSyncPlanAliases.entries)
        if (entry.value.length > 1) entry.key: entry.value,
    };

    expect(multi, {
      SyncPlanKeys.enrollmentSnapshots: ['enrollment_snapshots', 'enrollments'],
    });
  });

  test(
    'les vingt constantes déclarées sont exactement les clés de la table',
    () {
      expect(_kDeclaredPlanKeys.length, 20);
      expect(
        _kDeclaredPlanKeys.toSet().length,
        20,
        reason: 'deux constantes de SyncPlanKeys portent la même chaîne',
      );
      expect(_kDeclaredPlanKeys.toSet(), kSyncPlanAliases.keys.toSet());
    },
  );

  // ── L'ordre interne de la paire est porteur ───────────────────────────────

  test("enrollment.snapshots : l'hydratant précède le delta", () {
    // L hydratant INSÈRE les lignes que le delta, UPDATE-only, se contente de
    // mettre à jour. Inverser la paire laisserait le delta sans lignes à
    // toucher — des dossiers muets, sans la moindre erreur. D où une `List`
    // ordonnée, jamais un `Set`.
    final pair = resourcesOf(SyncPlanKeys.enrollmentSnapshots);

    expect(pair, ['enrollment_snapshots', 'enrollments']);
    expect(
      pair.indexOf('enrollment_snapshots'),
      lessThan(pair.indexOf('enrollments')),
    );
  });

  test("la DI enregistre elle aussi l'hydratant avant le delta", () {
    // La table d'alias ne sert à rien si le coordinateur, lui, exécute les deux
    // dans l'autre sens : c'est son ordre d'enregistrement qui gouverne
    // aujourd'hui (le plan n'est autorité qu'au lot F5).
    expect(
      registeredResources.indexOf('enrollment_snapshots'),
      lessThan(registeredResources.indexOf('enrollments')),
    );
  });

  // ── enrollment.deltas n'existe pas ────────────────────────────────────────

  test("enrollment.deltas n'est pas une clé de ce contrat", () {
    // Le catalogue V1.2 la liste encore comme un flux à part ; l'énumération
    // serveur l'a fusionnée dans `enrollment.snapshots`. La « rétablir »
    // produirait une clé jamais présente au plan et `enrollments` recensé deux
    // fois.
    const ghost = 'enrollment.deltas';

    expect(resourcesOf(ghost), isEmpty);
    expect(kSyncPlanAliases.containsKey(ghost), isFalse);
    expect(_kDeclaredPlanKeys, isNot(contains(ghost)));
    // Et le flux, lui, existe bel et bien — sous l'autre clé.
    expect(planKeyOf('enrollments'), SyncPlanKeys.enrollmentSnapshots);
  });

  test('resourcesOf rend une liste vide sur une clé inconnue, sans lever', () {
    // Un flux introduit côté serveur avant que le client sache le traiter est
    // prévu par le contrat : ce n'est pas une erreur, seulement une trace.
    expect(resourcesOf('flux.inexistant'), isEmpty);
    expect(planKeyOf('ressource_inexistante'), isNull);
  });

  // ── Les cinq correspondances non translittérables ─────────────────────────

  test('les cinq correspondances que nulle règle mécanique ne donne', () {
    // `.`/`-` → `_` marche pour treize clés sur dix-huit. Une règle qui échoue
    // une fois sur quatre n'en est pas une : ces cinq-là sont la raison d'être
    // de la table.
    expect(resourcesOf(SyncPlanKeys.schoolReferential), [
      'enrollment_referential',
    ]);
    expect(resourcesOf(SyncPlanKeys.enrollmentSnapshots)[1], 'enrollments');
    expect(resourcesOf(SyncPlanKeys.classroomClassrooms), ['classrooms']);
    expect(resourcesOf(SyncPlanKeys.attendanceRecords), ['attendance']);
    expect(resourcesOf(SyncPlanKeys.disciplineCases), ['disciplinary_cases']);
  });

  test('et ce sont les cinq SEULES que la règle mécanique manque', () {
    // La démonstration que la table doit exister, et qu'elle n'en fait pas
    // trop : sur les vingt couples (clé, ressource), `.`/`-` → `_` en donne
    // quatorze et manque exactement ces cinq-là. Si un jour la liste des
    // manquants change sans que personne l'ait décidé, c'est ici que ça se voit
    // — et « remplaçons la table par une règle » redevient un refus argumenté.
    String mechanical(String planKey) =>
        planKey.replaceAll('.', '_').replaceAll('-', '_');

    final broken = <String>[];
    for (final entry in kSyncPlanAliases.entries) {
      for (final resource in entry.value) {
        if (resource != mechanical(entry.key)) broken.add(resource);
      }
    }

    expect(broken, [
      'enrollment_referential', // school.referential — module renommé
      'enrollments', // enrollment.snapshots — 2e membre
      'classrooms', // classroom.classrooms — préfixe dédoublé
      'attendance', // attendance.records — suffixe tombé
      'disciplinary_cases', // discipline.cases — discipline → disciplinary
    ]);
  });

  // ── L'index inverse ───────────────────────────────────────────────────────

  test("planKeyOf est l'inverse exact de la table", () {
    for (final entry in kSyncPlanAliases.entries) {
      for (final resource in entry.value) {
        expect(
          planKeyOf(resource),
          entry.key,
          reason: 'index inverse incohérent pour « $resource »',
        );
      }
    }
  });

  test("aucune ressource n'est réclamée par deux clés", () {
    // Une ressource sous deux clés serait tirée deux fois par cycle sous F5 —
    // double comptage, et pour la Facturation deux passages sur le grand-livre.
    final claimants = <String, List<String>>{};
    for (final entry in kSyncPlanAliases.entries) {
      for (final resource in entry.value) {
        claimants.putIfAbsent(resource, () => []).add(entry.key);
      }
    }
    final shared = Map.fromEntries(
      claimants.entries.where((entry) => entry.value.length > 1),
    );

    expect(
      shared,
      isEmpty,
      reason: 'Ressources réclamées par deux clés : $shared',
    );
  });

  // ── isCursorKeyPrefix ─────────────────────────────────────────────────────

  test('isCursorKeyPrefix : vrai pour les huit ressources à suffixe', () {
    // Cf. la docstring de [_kSuffixedCursorResources] : la déduction depuis
    // `mode`/`scope` échouerait sur `editique_documents` et
    // `enrollment_reenrollment_cohort`, d'où une liste explicite.
    for (final resource in _kSuffixedCursorResources) {
      expect(
        isCursorKeyPrefix(resource),
        isTrue,
        reason: '« $resource » porte un suffixe de curseur',
      );
    }
    // Les huit sont bien des ressources réellement enregistrées, pas des
    // chaînes mortes.
    expect(
      registeredResources.toSet().containsAll(_kSuffixedCursorResources),
      isTrue,
    );
  });

  test('isCursorKeyPrefix : faux pour les treize ressources à clé nue', () {
    final bare = registeredResources.toSet().difference(
      _kSuffixedCursorResources,
    );

    expect(bare.length, 13);
    for (final resource in bare) {
      expect(
        isCursorKeyPrefix(resource),
        isFalse,
        reason:
            '« $resource » a une clé de curseur complète : la déclarer préfixe '
            "ferait chercher un suffixe qui n'existe pas",
      );
    }
  });

  test("isCursorKeyPrefix ignore ce qu'elle ne connaît pas", () {
    expect(isCursorKeyPrefix('ressource_inexistante'), isFalse);
    expect(isCursorKeyPrefix(''), isFalse);
  });
}
