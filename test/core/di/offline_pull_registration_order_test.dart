import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/refresh_ledger_before_collection_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/watch_ledger_revalidation_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/coordinator_payments_sync.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../features/offline_full_db.dart';

/// `PullCoordinator` qui **retient l'ordre d'enregistrement**.
///
/// C'est le seul moyen d'observer cet ordre depuis un test : le registre est
/// privé, et `pullAll()` est inutilisable ici (les vingt handlers réels
/// taperaient le réseau). L'ordre retenu est bien celui d'exécution — le
/// coordinateur itère `_handlers.values`, et une `LinkedHashMap` rend ses
/// valeurs dans l'ordre d'insertion des clés.
/// `FinanceLedgerRefresher` réclame la sonde de crédentiels au conteneur. Ce
/// montage n'exécute rien qui la consulte — la jambe éprouvée ici part APRÈS.
class _MockAuthSessionManager extends Mock implements AuthSessionManager {}

class _RecordingPullCoordinator extends PullCoordinator {
  _RecordingPullCoordinator({required super.connectivity});

  final List<PullHandler> registered = [];

  /// Les périmètres demandés par `pullSubset`. Sert à prouver qu'un chemin qui
  /// tirait en direct passe désormais par ici — cf. le test du seam paiements.
  final List<Set<String>> subsets = [];

  @override
  void registerHandler(PullHandler handler) {
    registered.add(handler);
    super.registerHandler(handler);
  }

  @override
  Future<PullRunReport> pullSubset(Set<String> resources) {
    subsets.add(resources);
    return super.pullSubset(resources);
  }
}

/// Rien ici ne doit tirer : le montage de la DI enregistre, il n'exécute pas.
class _AlwaysOffline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => false;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// L'ordre d'enregistrement des `PullHandler` sur le `PullCoordinator` **est**
/// leur ordre d'exécution, et personne ne l'observait : on pouvait permuter les
/// dix-neuf flux sans faire rougir un seul test, alors que quatre de ces arêtes
/// décident du sens de la panne (ADR-015 K).
///
/// Ce test monte la DI offline **réelle** (`registerOfflineModules`) plutôt
/// qu'une liste recopiée : une liste recopiée dériverait avec le code au lieu de
/// le contredire. Seul le coordinateur est substitué, par une sous-classe qui
/// note ce qu'on lui donne.
///
/// Le montage n'a besoin que du socle : tout le reste de la DI offline est
/// paresseux, et les rares résolutions immédiates (handlers d'outbox, repos de
/// pull) ne touchent que la base, `Dio` et la map d'extras.
void main() {
  late Database db;
  late GetIt getIt;
  late _RecordingPullCoordinator coordinator;

  setUp(() async {
    db = await openFullOfflineDb();
    getIt = GetIt.asNewInstance();
    coordinator = _RecordingPullCoordinator(connectivity: _AlwaysOffline());

    getIt.registerSingleton<Database>(db);
    getIt.registerSingleton<Map<String, dynamic>>(<String, dynamic>{});
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
    getIt.registerSingleton<Dio>(Dio());
    getIt.registerSingleton<CurrentUserContext>(CurrentUserContext());
    getIt.registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
    getIt.registerSingleton<SyncMetaDao>(SyncMetaDao(db));
    getIt.registerSingleton<AuthLocalDao>(AuthLocalDao(db));
    getIt.registerSingleton<ConnectivityService>(_AlwaysOffline());
    getIt.registerSingleton<SyncEngine>(
      SyncEngine(outbox: OutboxDao(db), connectivity: _AlwaysOffline()),
    );
    getIt.registerSingleton<PullCoordinator>(coordinator);
    getIt.registerSingleton<AuthSessionManager>(_MockAuthSessionManager());

    registerOfflineModules(getIt);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  List<String> order() =>
      coordinator.registered.map((h) => h.resource).toList();

  /// Échoue en nommant les deux ressources ET l'ordre observé : « une arête est
  /// cassée » n'a jamais permis de trouver laquelle.
  void expectBefore(String avant, String apres, String pourquoi) {
    final observe = order();
    expect(
      observe,
      contains(avant),
      reason: 'Ressource absente du registre : $avant',
    );
    expect(
      observe,
      contains(apres),
      reason: 'Ressource absente du registre : $apres',
    );
    expect(
      observe.indexOf(avant),
      lessThan(observe.indexOf(apres)),
      reason:
          '$avant doit être tiré AVANT $apres — $pourquoi.\nOrdre : $observe',
    );
  }

  group('arêtes d\'ordre du registre de pull (ADR-015 K)', () {
    // Les classes et leurs membres sont scopés par l'année courante, que seul le
    // référentiel Inscription pose en base. Tirés avant lui sur une tablette
    // neuve, les deux handlers Classe n'ont aucune année à interroger.
    test('le référentiel école précède les flux Classe', () {
      expectBefore(
        EnrollmentPullRepositoryImpl.referentialResource,
        kClassroomsResource,
        'les classes sont scopées par l\'année du référentiel',
      );
      expectBefore(
        EnrollmentPullRepositoryImpl.referentialResource,
        kClassroomMembersResource,
        'le roster est scopé par l\'année du référentiel',
      );
      expectBefore(
        EnrollmentPullRepositoryImpl.referentialResource,
        kClassroomTransfersResource,
        'les transferts sont scopés par l\'année du référentiel',
      );
    });

    // ADR-015 F6 — `SyncClassroomReferentialUseCase` tenait cet ordre lui-même
    // (« TOUJOURS après les classes, ne jamais inverser ») avant d'être replié
    // sur `pullSubset`. Le repli le confie au registre, qui n'en gardait
    // jusqu'ici aucune trace observable : c'est ici que l'invariant atterrit.
    // Le delta de transfert résout son `school_level_id` par un SELECT sur
    // `ref_classrooms` — dans l'autre ordre, la colonne se remplit d'une chaîne
    // vide.
    test('les classes précèdent les transferts', () {
      expectBefore(
        kClassroomsResource,
        kClassroomTransfersResource,
        'le delta de transfert résout school_level_id depuis ref_classrooms',
      );
    });

    // L'arête la plus chère du dépôt : dans l'autre sens, un paiement passe
    // SYNCED et sort du `pending` alors que `amount_paid` est encore périmé —
    // la créance s'affiche impayée et le caissier RÉENCAISSE.
    test(
      'les créances précèdent les paiements (sens de panne money-grade)',
      () {
        expectBefore(
          FinancePullRepositoryImpl.chargesResource,
          FinancePullRepositoryImpl.paymentsResource,
          'l\'ordre inverse fait réencaisser un versement déjà encaissé',
        );
      },
    );

    // CORRECTIF B — le bundle était enregistré DERNIER des six.
    test('le référentiel de notes précède les cours', () {
      expectBefore(
        kGradesReferentialResource,
        kAcademicsCoursResourcePrefix,
        'le détail d\'un cours lit le barème',
      );
    });

    test('les cours précèdent les évaluations', () {
      expectBefore(
        kAcademicsCoursResourcePrefix,
        kAcademicsEvaluationsResourcePrefix,
        'le pull des évaluations itère ref_cours',
      );
    });

    // Documentée comme porteuse dans `sync_plan_keys.dart` : le pull hydratant
    // INSÈRE les lignes que le delta maigre ne fait qu'UPDATE. Inversés, les
    // dossiers restent muets — sans la moindre erreur.
    test('les snapshots hydratants précèdent le delta d\'inscription', () {
      expectBefore(
        EnrollmentPullRepositoryImpl.snapshotsResource,
        EnrollmentPullRepositoryImpl.deltaResource,
        'le delta ne fait qu\'UPDATE les lignes insérées par les snapshots',
      );
    });
  });

  group('le registre lui-même', () {
    // Le compte fige la surface : un flux ajouté sans arête déclarée fait
    // rougir ici, ce qui force à trancher sa place plutôt qu'à la subir.
    test('vingt handlers, aucune ressource enregistrée deux fois', () {
      expect(coordinator.registered, hasLength(20));
      expect(
        order().toSet(),
        hasLength(20),
        reason: 'Doublon de ressource : ${order()}',
      );
    });

    // CORRECTIF A — le socle est une exception au filtre de permission, donc
    // une porte ouverte. Un second porteur du drapeau doit être une décision,
    // jamais un copier-coller : `isBaseline` sort son flux de TOUT filtre.
    test('un seul flux socle dans tout le dépôt, et c\'est le référentiel', () {
      final socles = coordinator.registered
          .where((h) => h.isBaseline)
          .map((h) => h.resource)
          .toList();

      expect(socles, [EnrollmentPullRepositoryImpl.referentialResource]);
    });

    // Les dix-huit autres restent gouvernés par leur permission : sans cette
    // assertion, le test ci-dessus passerait aussi si le drapeau avait disparu
    // du contrat et rendait `false` partout.
    test('les dix-neuf autres flux déclarent tous une exigence de lecture', () {
      final sansExigence = coordinator.registered
          .where((h) => !h.isBaseline && h.requiredPermissions.isEmpty)
          .map((h) => h.resource)
          .toList();

      // Une exigence vide serait pire qu'un oubli : `canAccess` refuse sur
      // exigence vide, le flux ne descendrait plus jamais.
      expect(sansExigence, isEmpty);
      expect(coordinator.registered.where((h) => !h.isBaseline), hasLength(19));
    });

    // Les autres handlers, notamment ceux du même module, ne doivent pas
    // récupérer le drapeau par héritage : `EnrollmentPullHandler` le porte en
    // CHAMP, partagé par ses cinq instances.
    test('les quatre autres flux Inscription ne sont pas socle', () {
      final inscriptionNonSocle = coordinator.registered
          .where(
            (h) => const {
              EnrollmentPullRepositoryImpl.cohortResource,
              EnrollmentPullRepositoryImpl.preEnrollmentsResource,
              EnrollmentPullRepositoryImpl.snapshotsResource,
              EnrollmentPullRepositoryImpl.deltaResource,
            }.contains(h.resource),
          )
          .toList();

      expect(inscriptionNonSocle, hasLength(4));
      expect(inscriptionNonSocle.every((h) => !h.isBaseline), isTrue);
    });
  });

  // Garde-fou du harnais : si un jour un registrar cessait d'enregistrer ses
  // handlers, tous les tests ci-dessus deviendraient verts par vacuité pour les
  // arêtes qu'ils ne trouveraient plus. On vérifie donc que les dix-neuf
  // ressources attendues sont là, nommément.
  test('les vingt ressources attendues sont toutes enregistrées', () {
    expect(order().toSet(), {
      EnrollmentPullRepositoryImpl.referentialResource,
      EnrollmentPullRepositoryImpl.cohortResource,
      EnrollmentPullRepositoryImpl.preEnrollmentsResource,
      EnrollmentPullRepositoryImpl.snapshotsResource,
      EnrollmentPullRepositoryImpl.deltaResource,
      FinancePullRepositoryImpl.chargesResource,
      FinancePullRepositoryImpl.paymentsResource,
      kClassroomsResource,
      kClassroomMembersResource,
      kClassroomTransfersResource,
      kAttendanceResource,
      kDisciplinaryResource,
      kScheduleTimeSlotsResource,
      kScheduleSessionsResource,
      kGradesReferentialResource,
      kAcademicsCoursResourcePrefix,
      kAcademicsEvaluationsResourcePrefix,
      kAcademicsNotesResourcePrefix,
      kEditiqueDocumentsResource,
      kBoutiqueSalesResource,
    });
  });

  group('le seam paiements du grand-livre passe par le coordinateur', () {
    // ⚠️ Treizième porte dérobée du lot F6, refermée après coup. L'exemption
    // accordée à Finance visait `finance_ledger:<studentId>`, dont la clé est
    // dynamique par élève ; le seam des PAIEMENTS, lui, tire le flux global
    // (`finance.payments`, handler enregistré ci-dessus) et n'avait aucune
    // raison d'échapper au plan.
    //
    // Ces deux tests montent la DI RÉELLE — c'est le seul niveau où « la classe
    // existe » et « la classe est branchée » cessent de se confondre. Ce dépôt a
    // déjà payé cinq gardes écrites, testées, et jamais injectées.

    test('il est résolvable depuis le conteneur', () {
      expect(() => getIt<CoordinatorPaymentsSync>(), returnsNormally);
      expect(
        getIt<CoordinatorPaymentsSync>(),
        same(getIt<CoordinatorPaymentsSync>()),
        reason: 'un singleton : deux instances tireraient deux fois',
      );
    });

    test('LE TEST DE LA PORTE : le refresher passe RÉELLEMENT par lui — pas '
        'seulement « la classe est enregistrée »', () async {
      // ⚠️ Sans ce test, la garde serait invérifiable. Prouver que
      // `CoordinatorPaymentsSync` est résolvable ne prouve PAS que c'est lui
      // qu'appelle le refresher : rebrancher le seam sur
      // `FinancePullRepository.syncPayments()` laissait les deux autres tests
      // de ce groupe parfaitement verts. Vérifié par mutation.
      await getIt<FinanceLedgerRefresher>().debugPullPaymentsOnly();

      expect(
        coordinator.subsets,
        [
          {FinancePullRepositoryImpl.paymentsResource},
        ],
        reason:
            'le seam paiements du refresher ne passe plus par le '
            'coordinateur : le flux global échappe de nouveau au plan, au '
            'filtre de droits et au bus de complétion',
      );
    });

    test(
      'et il demande EXACTEMENT le flux paiements au coordinateur enregistré',
      () async {
        // Hors ligne dans ce montage : le cycle ne tire rien, ce qui est sans
        // importance — ce qu'on observe est le périmètre DEMANDÉ, donc le fait
        // que l'appel atterrisse bien sur ce coordinateur-ci.
        final aJour = await getIt<CoordinatorPaymentsSync>()();

        expect(
          coordinator.subsets,
          [
            {FinancePullRepositoryImpl.paymentsResource},
          ],
          reason:
              'si ce seam repassait en direct sur '
              'FinancePullRepository.syncPayments(), le coordinateur ne verrait '
              'rien et le flux échapperait de nouveau au plan',
        );
        expect(
          aJour,
          isFalse,
          reason:
              'un cycle hors ligne n\'a rien observé : il ne doit jamais '
              'autoriser l\'estampille « à jour » sous les totaux',
        );
      },
    );
  });

  // ── M-8 : le régime stale-while-revalidate du détail Facturation ──────────
  // Les lectures n'attendent plus le rafraîchissement ; ce qui les rattrape est
  // un signal, et un signal se câble. Mal branché, il ne casse RIEN : l'écran
  // afficherait simplement des lignes qui ne se mettent jamais à jour, et une
  // base encore vide resterait « Aucun frais » toute la visite. Aucun test de
  // comportement ne broncherait — c'est le motif exact du lot F6.
  group('détail Facturation : lecture immédiate, revalidation annoncée', () {
    test('les trois pièces sortent du conteneur réel', () {
      expect(() => getIt<WatchLedgerRevalidationUseCase>(), returnsNormally);
      expect(
        () => getIt<RefreshLedgerBeforeCollectionUseCase>(),
        returnsNormally,
      );
      final cubit = getIt<LedgerRevalidationCubit>();
      addTearDown(cubit.close);
      expect(cubit.state, 0);
    });

    test('l\'écran écoute le canal DE ce refresher, pas un autre', () {
      // Un `FinanceLedgerRefresher` par résolution, et le signal que la fiche
      // écoute ne serait alimenté par aucune lecture.
      expect(
        getIt<FinanceLedgerRefresher>(),
        same(getIt<FinanceLedgerRefresher>()),
      );
      expect(
        getIt<WatchLedgerRevalidationUseCase>()(),
        same(getIt<FinanceLedgerRefresher>().revalidated),
      );
    });
  });
}
