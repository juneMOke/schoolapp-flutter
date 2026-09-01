import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/reduction_catalog_local_models.dart';

/// Nom de ressource du flux des préinscriptions — identité du `PullHandler`
/// devant le `PullCoordinator` et le plan de synchro (`kSyncPlanAliases`).
///
/// **Ce n'est PAS la clé du curseur.** Le curseur, lui, est scopé par école —
/// voir [preEnrollmentsCursorKey]. La distinction est la même que pour
/// l'éditique : le coordinateur nomme un flux, `sync_meta` mémorise où en est
/// une école dans ce flux.
const String kEnrollmentPreEnrollmentsResource = 'enrollment_pre_enrollments';

/// Clé `sync_meta` du curseur keyset des préinscriptions, **scopée par école**.
/// Le séparateur `@` est la convention du dépôt pour une ressource scopée.
///
/// Le flux est cadré par l'école du jeton, et `ref_pre_enrollments` n'a aucune
/// colonne `school_id` : un curseur unique sur une tablette réaffectée faisait
/// reprendre le second établissement au point où le premier s'était arrêté. Le
/// serveur répondait « rien de neuf », et les préinscriptions de la nouvelle
/// école ne descendaient jamais — exactement le défaut que la migration v18 a dû
/// corriger pour les caches cadrés enseignant (partition par compte).
///
/// ⚠️ **Cette clé orpheline la clé héritée non scopée**
/// (`enrollment_pre_enrollments`, écrite par toutes les versions antérieures) :
/// la ligne reste dans `sync_meta`, plus jamais lue, et chaque tablette du parc
/// rebootstrape ce flux au premier cycle qui suit la montée de version. C'est
/// **voulu** — c'est même le seul comportement correct, puisque rien ne permet
/// de savoir à quelle école ce curseur hérité appartenait. Le coût est borné
/// (le vivier des préinscriptions pèse quelques centaines de Ko) et il est payé
/// une fois.
///
/// Aucune purge de migration ne vise cette ancienne clé (les seules suppressions
/// dans `sync_meta` d'`app_database.dart` visent `academics_*`, `schedule_*` et
/// `classrooms`) : la ligne héritée survit donc à la montée de version, inerte.
/// Elle est en revanche balayée par [SyncMetaDao.deleteCursorsOf], dont le
/// prédicat couvre `<prefix>` autant que `<prefix>@…`.
String preEnrollmentsCursorKey(String schoolId) =>
    '$kEnrollmentPreEnrollmentsResource@$schoolId';

/// Pulls Inscription — miroir *lecture* de `openApi.yaml` (section Sync,
/// ADR-008/009). Trois régimes :
///  - **référentiel** ([syncReferential]) : bundle full always-200, curseur =
///    simple marqueur de fraîcheur (`serverTime`) ;
///  - **cohorte N-1** ([syncReenrollmentCohort]) : ressource STATIQUE paginée
///    par `cursorId` (= studentId), parcourue **jusqu'à `bootstrapComplete`**
///    puis remplacée d'un bloc (swap atomique). Un roster interrompu (réseau) est
///    **jeté** : ni remplacement ni avance du marqueur → « jamais un demi-roster » ;
///  - **keyset** ([syncPreEnrollments]/[syncEnrollmentDelta]/[syncEnrollmentSnapshots])
///    : pagination par `cursor` opaque — on suit `nextCursor` tant que `hasMore`
///    (curseur mémorisé à CHAQUE page → reprise), puis on mémorise `nextWatermark`
///    (début du prochain cycle, Δ appliqué). `cursor` absent = bootstrap ; 304 =
///    rien de neuf (curseur conservé).
///
/// La grille tarifaire du bundle est déléguée à la Facturation via le seam
/// [replaceTariffs], et le catalogue boutique à la caisse via
/// [replaceBoutiqueArticles].
class EnrollmentPullRepositoryImpl implements EnrollmentPullRepository {
  final EnrollmentPullApi api;
  final EnrollmentReferentialDao referentialDao;
  final EnrollmentSeedDao seedDao;
  final EnrollmentReconciliationDao reconciliationDao;
  final Future<void> Function(
    List<FeeTariffLocalModel> tariffs,
    List<String> academicYearIds,
  )
  replaceTariffs;

  /// Seam vers la Boutique, pour la même raison que [replaceTariffs] : le
  /// bundle porte une section `boutiqueArticles`, mais `enrollment` n'a rien à
  /// savoir du catalogue d'une caisse. L'isolation du module (invariant I-4)
  /// commencerait à se défaire par un import direct.
  final Future<void> Function(
    List<BoutiqueArticleLocalModel> articles,
    List<String> academicYearIds,
  )
  replaceBoutiqueArticles;

  /// Seam vers la Facturation pour le barème de réductions (ADR-021), pour la
  /// même raison que [replaceTariffs].
  ///
  /// Signature **scopée école et non année**, et c'est ce qui la distingue des
  /// deux autres : les tables du barème n'ont pas d'`academic_year_id` — il
  /// descend à la racine du bundle. Passer une liste d'années ici n'aurait rien
  /// à quoi correspondre.
  final Future<void> Function(
    List<ReductionTypeLocalModel> types,
    List<ReductionLineLocalModel> lines,
    String schoolId,
  )
  replaceReductionCatalog;
  final SyncMetaDao syncMetaDao;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext currentUser;
  final Clock now;

  /// Clés de curseur/fraîcheur dans `sync_meta` (une par ressource).
  static const String referentialResource = 'enrollment_referential';
  static const String cohortResource = 'enrollment_reenrollment_cohort';
  static const String deltaResource = 'enrollments';

  /// Nom de ressource des préinscriptions — **pas** la clé de son curseur, qui
  /// est scopée par école ([preEnrollmentsCursorKey]).
  static const String preEnrollmentsResource =
      kEnrollmentPreEnrollmentsResource;

  /// Curseur du pull HYDRATANT — distinct du delta maigre (`deltaResource`) :
  /// les deux flux avancent indépendamment (le hydratant crée les lignes, le
  /// maigre ne fait que les réconcilier).
  static const String snapshotsResource = 'enrollment_snapshots';

  /// Taille de page keyset/cohorte (défaut serveur = 100, borné [1, 500]).
  static const int pageLimit = 100;

  const EnrollmentPullRepositoryImpl({
    required this.api,
    required this.referentialDao,
    required this.seedDao,
    required this.reconciliationDao,
    required this.replaceTariffs,
    required this.replaceBoutiqueArticles,
    required this.replaceReductionCatalog,
    required this.syncMetaDao,
    required this.requiredAuth,
    required this.currentUser,
    this.now = systemClock,
  });

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncReferential() async {
    final syncedAt = now();
    try {
      final response = await api.pullReferential(requiredAuth);
      final applied = await _applyReferential(response.data, syncedAt);
      final cursor = response.data.serverTime;
      await syncMetaDao.setCursor(
        referentialResource,
        cursor: cursor,
        syncedAt: syncedAt,
      );
      return Right(_outcome(applied, syncedAt, cursor, serverTime: cursor));
    } on DioException catch (e) {
      return _mapDioError(e);
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid enrollment pull payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>>
  syncReenrollmentCohort() async {
    final syncedAt = now();
    // Skip-si-complet **scopé par saison** : la cohorte N-1 est gelée sur la
    // saison (D3) — une fois le roster intégralement pullé, plus rien n'évolue
    // côté serveur, donc aucun intérêt à re-scanner à chaque montage du module.
    // Le marqueur est keyé par l'année académique COURANTE (résolue localement
    // via `ref_academic_years`, peuplée par le pull référentiel qui précède) :
    // un rollover d'année → nouvelle clé → re-pull automatique (la base offline
    // survit au logout/rollover — voir OFFLINE_GAP_ANALYSIS). Le curseur n'étant
    // posé QU'au succès total (jamais sur un roster partiel/échoué), sa présence
    // vaut « roster complet en cache pour cette saison » → court-circuit sans
    // réseau. Année non résolue (base fraîche) → clé de repli non scopée.
    final currentYearId = await seedDao.findCurrentAcademicYearId();
    final markerKey = _cohortMarkerKey(currentYearId);
    final done = await syncMetaDao.getCursor(markerKey);
    if (done != null) {
      return Right(EnrollmentPullOutcome.notModifiedAt(syncedAt, done));
    }
    try {
      final all = <ReenrollmentCandidateDto>[];
      String? cursorId; // null = première page
      String serverTime = '';
      var complete = false;
      while (true) {
        final response = await api.pullReenrollmentCohort(
          requiredAuth,
          cursorId,
          null,
          pageLimit,
        );
        final body = response.data;
        all.addAll(body.items);
        serverTime = body.serverTime;
        if (body.bootstrapComplete) {
          complete = true;
          break;
        }
        // Gardes anti-boucle : sans complétion, un `nextCursorId` absent OU
        // identique à celui envoyé (keyset studentId strictement croissant) =
        // aucun progrès → roster incomplet (jeté plus bas), jamais une boucle
        // infinie qui gonfle `all` en mémoire (symétrique de `_keysetPull`).
        if (body.nextCursorId == null || body.nextCursorId == cursorId) break;
        cursorId = body.nextCursorId;
      }
      if (!complete) {
        // Roster partiel : NE PAS remplacer le snapshot ni avancer le marqueur
        // (un device interrompu ne doit pas croire tenir tout le roster). Rejoué
        // depuis la première page au prochain cycle.
        return const Left(
          ServerFailure('Reenrollment cohort roster incomplete'),
        );
      }
      final upserted = await seedDao.replaceReenrollmentCohort(
        all,
        syncedAt: syncedAt,
      );
      await syncMetaDao.setCursor(
        markerKey,
        cursor: serverTime,
        syncedAt: syncedAt,
      );
      return Right(
        _outcome(upserted, syncedAt, serverTime, serverTime: serverTime),
      );
    } on DioException catch (e) {
      return _mapDioError(e);
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid enrollment pull payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncPreEnrollments() async {
    // École inconnue → NI appel réseau, NI écriture (même forme que la garde
    // d'hydratation du delta ci-dessous). Se rabattre ici sur la clé plate
    // rétablirait mot pour mot le défaut que ce scope ferme : un curseur qu'une
    // AUTRE école héritera. Et `ref_pre_enrollments` n'ayant pas de colonne
    // `school_id`, des lignes descendues sans école connue seraient
    // inattribuables — donc ni distinguables, ni purgeables par le changement
    // d'école. Mieux vaut un vivier vide qu'un vivier mélangé.
    final schoolId = currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return Right(EnrollmentPullOutcome.notModifiedAt(now(), null));
    }
    return _keysetPull<PreEnrollmentDto, PreEnrollmentsPageDto>(
      cursorKey: preEnrollmentsCursorKey(schoolId),
      request: (cursor) =>
          api.pullPreEnrollments(requiredAuth, cursor, pageLimit),
      apply: (items, syncedAt) =>
          seedDao.upsertPreEnrollments(items, syncedAt: syncedAt),
    );
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncEnrollmentDelta() async {
    // ⚠️ LE DELTA NE PART PAS SUR UNE BASE JAMAIS HYDRATÉE — il y brûlerait son
    // backlog, en silence.
    //
    // Le delta est maigre : `applyEnrollmentDelta` ne fait qu'UPDATE des lignes
    // que seul l'hydratant INSERT. Sans hydratation, chaque page ne met à jour
    // rien du tout — mais `_keysetPull` mémorise le jeton à CHAQUE page, sans
    // jamais regarder `upserted`. Le backlog serveur est donc consommé et le
    // curseur avancé au-delà de dossiers que plus rien ne redemandera : les
    // modifications de cette fenêtre sont perdues jusqu'à un rebootstrap.
    //
    // Et l'incident est invisible : zéro ligne appliquée est replié en
    // `notModified` par `_outcome`, exactement comme un cycle sain. Pas
    // d'erreur, pas de compteur, aucun événement de bus — rien à quoi
    // s'accrocher pour comprendre pourquoi des dossiers sont figés.
    //
    // La garde vit ICI, dans le repository, et non dans le `PullHandler`.
    //
    // ⚠️ Sa justification d'origine est PÉRIMÉE et ne doit pas être ressortie :
    // elle disait que `SyncEnrollmentPullsUseCase` appelait ces méthodes EN
    // DIRECT au montage des FeatureScope Inscription, Facturation et Documents,
    // hors de tout handler. Ce n'est plus vrai depuis le repli F6 — ce use case
    // ne fait plus que demander un sous-ensemble au `PullCoordinator`, et tout
    // passe donc par les handlers.
    //
    // La garde reste néanmoins nécessaire, et à cette place : le coordinateur
    // tire aussi le delta seul (`pullSubset` d'un écran qui ne demanderait que
    // lui, ou un plan de synchro qui n'accorderait que ce flux), et le
    // repository est le seul niveau où la question « cette base a-t-elle jamais
    // été hydratée ? » se pose sans dupliquer le curseur de l'hydratant.
    //
    // Le curseur de l'hydratant fait office de témoin : il n'existe qu'après
    // une première page appliquée. Ce n'est pas un drapeau de bootstrap
    // COMPLET — cette paire n'en a pas, contrairement à `attendance` ou
    // `schedule` — mais il suffit à distinguer « jamais hydraté » du reste, qui
    // est le seul cas où le delta détruit.
    //
    // Dans un cycle normal l'ordre d'enregistrement fait passer l'hydratant en
    // premier : au moment où le delta s'exécute, le curseur est déjà posé et la
    // garde laisse passer. Elle ne mord donc que sur un ordre inversé, ou sur
    // un chemin qui tirerait le delta seul.
    final hydrated = await _hasEverHydrated();
    if (!hydrated) {
      // NI appel réseau, NI écriture : surtout pas de `setCursor`, qui
      // bumperait la fraîcheur et ferait lire « à jour » à une ressource qu'on
      // vient délibérément de ne pas demander.
      return Right(EnrollmentPullOutcome.notModifiedAt(now(), null));
    }
    return _keysetPull<EnrollmentDeltaDto, EnrollmentDeltaPageDto>(
      cursorKey: deltaResource,
      request: (cursor) =>
          api.pullEnrollmentDelta(requiredAuth, cursor, null, pageLimit),
      apply: (items, syncedAt) =>
          reconciliationDao.applyEnrollmentDelta(items, syncedAt: syncedAt),
    );
  }

  /// L'hydratant a-t-il déjà posé son curseur ?
  ///
  /// Défensif comme le reste de la couche : une base indisponible rend `true`,
  /// pour que la garde ne puisse jamais devenir elle-même la cause d'un flux
  /// qui ne descend plus. Le pire qu'elle risque alors est de laisser passer un
  /// delta qu'elle aurait retenu — le comportement d'avant cette garde.
  Future<bool> _hasEverHydrated() async {
    try {
      return await syncMetaDao.getCursor(snapshotsResource) != null;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncEnrollmentSnapshots() =>
      _keysetPull<EnrollmentAggregateSnapshotDto, EnrollmentSnapshotPageDto>(
        cursorKey: snapshotsResource,
        request: (cursor) =>
            api.pullEnrollmentSnapshots(requiredAuth, cursor, null, pageLimit),
        apply: (items, syncedAt) => reconciliationDao.upsertEnrollmentSnapshots(
          items,
          syncedAt: syncedAt,
        ),
      );

  /// Squelette de pull **keyset** (préinscriptions / delta / snapshots) :
  /// parcourt les pages depuis le curseur mémorisé (`null` = bootstrap), applique
  /// chaque page en lot, et **mémorise le jeton à CHAQUE page** — `nextCursor`
  /// tant que `hasMore` (reprise en cas d'interruption), puis `nextWatermark` en
  /// fin de cycle (Δ appliqué). Le 304 (rien de neuf) arrive en [DioException] :
  /// fraîcheur bumpée, curseur conservé. Ne lève pas.
  ///
  /// [cursorKey] est une clé `sync_meta`, **pas** un nom de ressource de
  /// coordinateur : les préinscriptions y passent une clé scopée par école
  /// ([preEnrollmentsCursorKey]) alors que leur handler garde le nom plat.
  Future<Either<Failure, EnrollmentPullOutcome>>
  _keysetPull<I, P extends KeysetPageDto<I>>({
    required String cursorKey,
    required Future<HttpResponse<P>> Function(String? cursor) request,
    required Future<int> Function(List<I> items, int syncedAt) apply,
  }) async {
    final syncedAt = now();
    try {
      var cursor = await syncMetaDao.getCursor(cursorKey); // null = bootstrap
      var upserted = 0;
      String? lastServerTime;
      while (true) {
        final sent = cursor;
        final response = await request(sent);
        final body = response.data;
        if (body.items.isNotEmpty) {
          upserted += await apply(body.items, syncedAt);
        }
        final env = body.page;
        lastServerTime = env.serverTime;
        // `nextCursor` (progression) tant que `hasMore`, sinon `nextWatermark`
        // (fin de cycle). `null` (page vide de fin) → curseur conservé.
        final nextToken = env.cursorToPersist;
        if (nextToken != null) cursor = nextToken;
        await syncMetaDao.setCursor(
          cursorKey,
          cursor: cursor,
          syncedAt: syncedAt,
        );
        if (!env.hasMore) break; // dernière page
        // Gardes anti-boucle : le keyset est strictement croissant, donc un
        // `nextCursor` absent OU identique à celui envoyé = serveur défaillant
        // (sinon on rejouerait la même page à l'infini — cf. historique verrou
        // sqflite).
        if (env.nextCursor == null || env.nextCursor == sent) break;
      }
      return Right(
        _outcome(upserted, syncedAt, cursor, serverTime: lastServerTime),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        final previous = await syncMetaDao.getCursor(cursorKey);
        await syncMetaDao.setCursor(
          cursorKey,
          cursor: previous,
          syncedAt: syncedAt,
        );
        return Right(EnrollmentPullOutcome.notModifiedAt(syncedAt, previous));
      }
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid enrollment pull payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  /// École/années/cycles/niveaux via [referentialDao] + grille tarifaire via
  /// [replaceTariffs] (`label` serveur nullable replié sur `fee_code` :
  /// colonne NOT NULL), le tout **scopé** aux années du bundle — `current` +
  /// `previous` s'il est présent (purge des lignes disparues du snapshot).
  /// Deux transactions distinctes (le seam ne traverse pas les modules) : un
  /// échec des tarifs laisse le référentiel appliqué mais le curseur
  /// N'AVANCE PAS → l'intégralité est rejouée au pull suivant.
  Future<int> _applyReferential(ReferentialBundleDto body, int syncedAt) async {
    final upserted = await referentialDao.upsertReferential(
      body,
      syncedAt: syncedAt,
      schoolId: currentUser.schoolId ?? '',
    );
    // Portion réservée (ADR-014 §4) : le serveur envoie `feeTariffs: null` —
    // et non `[]` — quand l'appelant n'a pas `finance.grid.read`. `null` dit
    // « je ne te la montre pas », jamais « cette école n'a pas de tarifs ».
    // Replier l'un sur l'autre ferait lire à la purge scopée un ordre de tout
    // supprimer : la purge ne connaît que l'année, pas le compte, donc sur une
    // tablette partagée un pull sans ce droit effacerait la grille dont dépend
    // l'inscription hors ligne d'un autre poste. On ne purge donc QUE les
    // années dont le bundle a réellement porté sa section — une section
    // présente mais vide reste, elle, un ordre de purge légitime.
    final tariffBundles = <ReferentialYearBundleDto>[
      if (body.current.feeTariffs != null) body.current,
      if (body.previous?.feeTariffs != null) body.previous!,
    ];
    final boutiqueApplied = await _applyBoutiqueCatalog(body);
    final reductionsApplied = await _applyReductionCatalog(body, syncedAt);
    if (tariffBundles.isEmpty) {
      return upserted + boutiqueApplied + reductionsApplied;
    }

    final allTariffs = [for (final b in tariffBundles) ...b.feeTariffs!];
    final yearIds = <String>{
      for (final b in tariffBundles) b.academicYear.id,
      for (final b in tariffBundles)
        for (final g in b.schoolLevelGroups) g.academicYearId,
      for (final t in allTariffs) t.academicYearId,
    }.toList(growable: false);
    await replaceTariffs(
      allTariffs
          .map(
            (t) => FeeTariffLocalModel(
              id: t.id,
              academicYearId: t.academicYearId,
              schoolLevelId: t.schoolLevelId,
              schoolLevelGroupId: t.schoolLevelGroupId,
              feeCode: t.feeCode,
              // Repli sur `null`, jamais sur la nature : un code qui vaut le
              // `fee_code` ne distingue rien, et le fabriquer ici ferait passer
              // « l'école n'a pas saisi de code » pour « elle en a saisi un ».
              code: t.code,
              label: t.label ?? t.feeCode,
              amountInCents: t.amountInCents,
              currency: t.currency,
              dueAt: t.dueAt,
              syncedAt: syncedAt,
              updatedAt: syncedAt,
            ),
          )
          .toList(growable: false),
      yearIds,
    );
    return upserted + allTariffs.length + boutiqueApplied + reductionsApplied;
  }

  /// Barème de réductions du bundle → Facturation, par le seam
  /// [replaceReductionCatalog].
  ///
  /// **Même caviardage que la grille tarifaire, purge d'une autre nature.** Le
  /// serveur retire la section à qui n'a pas `finance.grid.read` et l'envoie à
  /// `null`, jamais à `[]`. Mais ces tables n'ont pas d'année : le scope de la
  /// purge est l'ÉCOLE, et il n'existe donc aucun filtre d'année pour amortir
  /// une erreur ici. Une section absente doit rester un non-événement —
  /// c'est aussi ce qui permet à ce code de tourner contre un serveur qui ne
  /// porterait pas encore la section.
  ///
  /// **Une section, pas deux.** Les lignes descendent imbriquées dans leur
  /// type ; l'aplatissement local leur stampe le code du parent. Rien à
  /// joindre, donc rien à désynchroniser — c'est la raison que le serveur
  /// donne lui-même d'imbriquer.
  ///
  /// `schoolId` vient de [currentUser], **jamais du payload** : c'est la clé de
  /// purge, et la laisser au serveur reviendrait à lui confier de quoi effacer
  /// le barème d'une école qu'il ne sait pas présente sur cette tablette.
  Future<int> _applyReductionCatalog(
    ReferentialBundleDto body,
    int syncedAt,
  ) async {
    final reductions = body.reductions;
    if (reductions == null) return 0;

    final schoolId = currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return 0;

    final lines = [
      for (final reduction in reductions)
        for (final line in reduction.lines)
          ReductionLineLocalModel(
            schoolId: schoolId,
            reductionCode: reduction.code,
            feeCode: line.feeCode,
            percentage: line.percentage,
            syncedAt: syncedAt,
          ),
    ];

    await replaceReductionCatalog(
      [
        for (final reduction in reductions)
          ReductionTypeLocalModel(
            schoolId: schoolId,
            code: reduction.code,
            label: reduction.label,
            active: reduction.active,
            syncedAt: syncedAt,
          ),
      ],
      lines,
      schoolId,
    );
    return reductions.length + lines.length;
  }

  /// Catalogue boutique du bundle → caisse, par le seam
  /// [replaceBoutiqueArticles].
  ///
  /// **Même caviardage que la grille tarifaire, même piège.** Le serveur envoie
  /// `boutiqueArticles: null` — et non `[]` — à qui n'a pas
  /// `boutique.catalog.read`. Replier l'un sur l'autre ferait lire à la purge
  /// scopée un ordre de tout supprimer : sur une tablette partagée, un pull par
  /// un compte sans ce droit effacerait le catalogue dont dépend la caisse d'un
  /// autre poste. On ne purge donc QUE les années dont le bundle a réellement
  /// porté sa section — une section présente mais vide reste, elle, un ordre de
  /// purge légitime (l'école n'a pas d'article).
  ///
  /// Un article dont l'année ne serait pas celle de son bundle est **ignoré**
  /// plutôt que rangé sous l'année du bundle : la purge est scopée par année, et
  /// l'y ranger d'office rendrait le catalogue d'une autre année invisible sans
  /// qu'aucune requête n'échoue.
  Future<int> _applyBoutiqueCatalog(ReferentialBundleDto body) async {
    final bundles = <ReferentialYearBundleDto>[
      if (body.current.boutiqueArticles != null) body.current,
      if (body.previous?.boutiqueArticles != null) body.previous!,
    ];
    if (bundles.isEmpty) return 0;

    final articles = [
      for (final bundle in bundles)
        for (final article in bundle.boutiqueArticles!)
          BoutiqueArticleLocalModel(
            id: article.id,
            academicYearId: article.academicYearId,
            code: article.code,
            label: article.label,
            // Le `?? ''` n'est PAS un repli sur une famille : la colonne est
            // NOT NULL, et une chaîne vide ne correspond à aucune constante,
            // donc `ArticleFamily.fromWire` rendra `null` et l'article se
            // rangera à part. Écrire ici « FOURNITURES » lui donnerait une
            // place et une couleur que personne n'a choisies.
            family: article.family ?? '',
            pricingMode: article.pricingMode ?? '',
            unitPriceInCents: article.unitPriceInCents,
            levelPrices: {
              for (final price in article.levelPrices)
                price.schoolLevelId: price.priceInCents,
            },
            currency: article.currency,
          ),
    ];
    final yearIds = <String>{
      for (final bundle in bundles) bundle.academicYear.id,
    }.toList(growable: false);

    await replaceBoutiqueArticles([
      for (final article in articles)
        if (yearIds.contains(article.academicYearId)) article,
    ], yearIds);
    return articles.length;
  }

  /// Bilan d'un pull : `notModified` si aucune ligne locale écrite (curseur tout
  /// de même mémorisé — delta vide, ADR-008), `updated` sinon. [serverTime]
  /// (ISO-8601) alimente [EnrollmentPullOutcome.serverTimeMs] sur la branche
  /// `updated` uniquement.
  EnrollmentPullOutcome _outcome(
    int applied,
    int syncedAt,
    String? cursor, {
    String? serverTime,
  }) => applied == 0
      ? EnrollmentPullOutcome.notModifiedAt(syncedAt, cursor)
      : EnrollmentPullOutcome(
          upserted: applied,
          notModified: false,
          syncedAt: syncedAt,
          cursor: cursor,
          serverTimeMs: serverTime == null
              ? null
              : EpochIsoHelper.tryToEpochMs(serverTime),
        );

  Either<Failure, EnrollmentPullOutcome> _mapDioError(DioException e) {
    if (e.error is Failure) return Left(e.error as Failure);
    return const Left(NetworkFailure('Network error occurred'));
  }

  /// Clé `sync_meta` du marqueur « roster complet » de la cohorte, **scopée par
  /// l'année académique courante** (`enrollment_reenrollment_cohort:<year>`) pour
  /// s'invalider seule au rollover d'année. Année non résolue (référentiel non
  /// encore synchronisé) → clé de repli non scopée [cohortResource].
  String _cohortMarkerKey(String? currentYearId) =>
      currentYearId == null ? cohortResource : '$cohortResource:$currentYearId';
}
