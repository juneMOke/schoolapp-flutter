import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
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
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../features/offline_full_db.dart';

/// `PullCoordinator` qui **retient l'ordre d'enregistrement**.
///
/// C'est le seul moyen d'observer cet ordre depuis un test : le registre est
/// privé, et `pullAll()` est inutilisable ici (les dix-neuf handlers réels
/// taperaient le réseau). L'ordre retenu est bien celui d'exécution — le
/// coordinateur itère `_handlers.values`, et une `LinkedHashMap` rend ses
/// valeurs dans l'ordre d'insertion des clés.
class _RecordingPullCoordinator extends PullCoordinator {
  _RecordingPullCoordinator({required super.connectivity});

  final List<PullHandler> registered = [];

  @override
  void registerHandler(PullHandler handler) {
    registered.add(handler);
    super.registerHandler(handler);
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
    test('dix-neuf handlers, aucune ressource enregistrée deux fois', () {
      expect(coordinator.registered, hasLength(19));
      expect(
        order().toSet(),
        hasLength(19),
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
    test('les dix-huit autres flux déclarent tous une exigence de lecture', () {
      final sansExigence = coordinator.registered
          .where((h) => !h.isBaseline && h.requiredPermissions.isEmpty)
          .map((h) => h.resource)
          .toList();

      // Une exigence vide serait pire qu'un oubli : `canAccess` refuse sur
      // exigence vide, le flux ne descendrait plus jamais.
      expect(sansExigence, isEmpty);
      expect(coordinator.registered.where((h) => !h.isBaseline), hasLength(18));
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
  test('les dix-neuf ressources attendues sont toutes enregistrées', () {
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
    });
  });
}
