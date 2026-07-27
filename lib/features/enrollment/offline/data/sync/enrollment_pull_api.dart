import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';

part 'enrollment_pull_api.g.dart';

/// Clients des PULL d'inscription (miroir strict de `openApi.yaml`, section
/// Sync — ADR-008/009).
///
/// Chaque méthode renvoie un [HttpResponse] pour exposer à l'appelant le corps
/// et le statut. Deux régimes de pagination :
///  - **référentiel** : bundle full always-200 (aucun curseur, gelé sur la
///    saison) ;
///  - **cohorte N-1** : ressource STATIQUE paginée par `cursorId` (= studentId),
///    always-200, drapeau `bootstrapComplete` en fin de roster (ni watermark ni
///    304) ;
///  - **préinscriptions / delta maigre / snapshots hydratants** : pagination
///    **keyset** par `cursor` opaque (base64url) — le client suit `nextCursor`
///    tant que `hasMore`, puis mémorise `nextWatermark` (début du prochain
///    cycle, Δ appliqué). `cursor` absent → bootstrap. Rien de neuf → `304 Not
///    Modified` (corps vide) qui arrive comme une [DioException] de statut 304
///    (hors 2xx, idiome socle cf. `ClassroomPullApi`). `hasMore=false` ≠ 304 :
///    c'est la dernière page.
///
/// `limit` = taille de page (défaut serveur 100, borné [1, 500]). Le token porte
/// le `school_id`.
@RestApi()
abstract class EnrollmentPullApi {
  factory EnrollmentPullApi(Dio dio, {String baseUrl}) = _EnrollmentPullApi;

  /// Bundle référentiel (école, années courante/précédente, cycles, niveaux,
  /// tarifs) — always-200. Aucun paramètre : `current`/`previous` sont
  /// toujours dérivés du tenant côté serveur (D1 — pas d'override d'année).
  @GET(AppConstants.syncReferentialEndpoint)
  Future<HttpResponse<ReferentialBundleDto>> pullReferential(
    @Extras() Map<String, dynamic> extras,
  );

  /// Cohorte de réinscription N-1 (bornée/statique) — always-200, paginée par
  /// `cursorId` (= `studentId` du dernier item de la page précédente).
  @GET(AppConstants.syncReenrollmentCohortEndpoint)
  Future<HttpResponse<ReenrollmentCohortPageDto>> pullReenrollmentCohort(
    @Extras() Map<String, dynamic> extras,
    @Query('cursorId') String? cursorId,
    @Query('previousAcademicYearId') String? previousAcademicYearId,
    @Query('limit') int? limit,
  );

  /// Préinscriptions en ligne (delta keyset `cursor`).
  @GET(AppConstants.syncPreEnrollmentsEndpoint)
  Future<HttpResponse<PreEnrollmentsPageDto>> pullPreEnrollments(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  /// Delta descendant MAIGRE des inscriptions (réconciliation multi-tablettes,
  /// projection maigre) — pagination keyset `cursor`.
  @GET(AppConstants.syncEnrollmentsEndpoint)
  Future<HttpResponse<EnrollmentDeltaPageDto>> pullEnrollmentDelta(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('academicYearId') String? academicYearId,
    @Query('limit') int? limit,
  );

  /// Pull HYDRATANT (agrégats complets = inscription + élève canonique +
  /// tuteurs), pour reconstituer une tablette neuve — pagination keyset `cursor`.
  @GET(AppConstants.syncEnrollmentSnapshotsEndpoint)
  Future<HttpResponse<EnrollmentSnapshotPageDto>> pullEnrollmentSnapshots(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('academicYearId') String? academicYearId,
    @Query('limit') int? limit,
  );
}
