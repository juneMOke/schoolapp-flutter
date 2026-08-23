import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_projector.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_summary_query.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';

// Contrats de liste partagés : un seul import (`enrollment_local_list_bloc.dart`)
// suffit aux widgets du listing pour l'état + le statut + le type/photo de requête.
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_summary_query.dart';

part 'enrollment_local_list_event.dart';
part 'enrollment_local_list_state.dart';

/// BLoC **dédié** au listing LOCAL des inscriptions (bascule dure 100 % local).
///
/// Séparé du bloc convergé du wizard (`EnrollmentOfflineBloc`) — qui porte le
/// brouillon et le détail sur un état scellé unique — pour éviter toute
/// collision d'état (un détail poussé ne doit pas repeindre la liste sous-
/// jacente) et ne pas gonfler ce god-bloc. Séparé aussi du bloc online
/// `EnrollmentBloc` : ici, **aucune** lecture réseau.
///
/// Les lectures locales du DAO étant grossières, le raffinement des critères
/// (nom/surnom/DOB) et la pagination sont faits côté client via
/// [EnrollmentLocalListProjector]. Le cache [_cache] conserve la liste filtrée
/// complète pour paginer sans re-lire la base.
class EnrollmentLocalListBloc
    extends Bloc<EnrollmentLocalListEvent, EnrollmentLocalListState> {
  final GetLocalEnrollmentsUseCase _getEnrollments;
  final SearchLocalEnrollmentsUseCase _search;

  List<EnrollmentSummary> _cache = const <EnrollmentSummary>[];

  // Générations de chargement : le transformer par défaut du bloc étant
  // `concurrent`, plusieurs `_load` peuvent voler en parallèle. Chaque `_load`
  // capture le numéro courant ; seul le PLUS RÉCENT écrit `_cache` et émet son
  // résultat (sémantique restartable, sans dépendance `bloc_concurrency`) — une
  // recherche périmée résolue en dernier ne peut plus gagner la course et
  // repeindre la liste sous une identité de requête plus fraîche.
  int _loadGeneration = 0;

  /// Tous les résultats de la dernière requête **résolue**, pages confondues —
  /// ce que l'état ne porte pas (il n'en garde que la page affichée).
  ///
  /// Pour un export : sans ça, « Exporter » ne rendrait que la page courante
  /// sous un décompte qui en annonce beaucoup plus, et le fichier serait
  /// silencieusement tronqué. Ne vaut que sur un état `success` — pendant un
  /// chargement le cache appartient encore à la requête précédente, exactement
  /// comme pour la pagination.
  List<EnrollmentSummary> get loadedSummaries =>
      List<EnrollmentSummary>.unmodifiable(_cache);

  EnrollmentLocalListBloc({
    required GetLocalEnrollmentsUseCase getEnrollments,
    required SearchLocalEnrollmentsUseCase search,
  }) : _getEnrollments = getEnrollments,
       _search = search,
       super(const EnrollmentLocalListState.initial()) {
    on<LocalListResetRequested>(_onReset);
    on<LocalListRefreshRequested>(_onRefresh);
    on<LocalListPageRequested>(_onPage);
    on<LocalListByStatusRequested>(_onByStatus);
    on<LocalListByStudentNameRequested>(_onByStudentName);
    on<LocalListByStudentNamesAndDateOfBirthRequested>(
      _onByStudentNamesAndDateOfBirth,
    );
    on<LocalListByDateOfBirthRequested>(_onByDateOfBirth);
    on<LocalListByAcademicInfoRequested>(_onByAcademicInfo);
    on<LocalListByPreEnrollmentAcademicInfoRequested>(
      _onByPreEnrollmentAcademicInfo,
    );
    on<LocalListByEnrolledAcademicInfoRequested>(_onByEnrolledAcademicInfo);
    on<LocalListByAcademicInfoAndStatusRequested>(_onByAcademicInfoAndStatus);
  }

  void _onReset(
    LocalListResetRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) {
    _loadGeneration++; // invalide tout _load en vol (ne clobberera pas le reset)
    _cache = const <EnrollmentSummary>[];
    emit(const EnrollmentLocalListState.initial());
  }

  Future<void> _onRefresh(
    LocalListRefreshRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) async {
    final last = state.lastSummariesQuery;
    if (last == null) return;
    await _load(emit, last);
  }

  void _onPage(
    LocalListPageRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) {
    final last = state.lastSummariesQuery;
    if (last == null) return;
    // Pagination seulement sur une liste settled : pendant un chargement en vol
    // `_cache` peut encore appartenir à la requête précédente (on paginerait
    // alors des données périmées sous la nouvelle identité de requête).
    if (state.summariesStatus != EnrollmentLoadStatus.success) return;

    final totalPages = state.summariesTotalPages;
    // Repli 0 (et non event.page) quand il n'y a aucune page : `paginate`
    // re-borne de toute façon, et un event.page négatif rendrait
    // `clamp(0, maxPage)` invalide (lowerLimit > upperLimit → exception).
    final maxPage = totalPages > 0 ? totalPages - 1 : 0;
    final nextPage = event.page.clamp(0, maxPage);

    final pageData = EnrollmentLocalListProjector.paginate(
      _cache,
      page: nextPage,
      size: last.size,
    );
    emit(_successState(last.copyWithPage(nextPage), pageData));
  }

  Future<void> _onByStatus(
    LocalListByStatusRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byStatus,
      status: event.status,
      academicYearId: event.academicYearId,
      enrollmentType: event.enrollmentType,
      page: event.page,
      size: event.size,
    ),
  );

  Future<void> _onByStudentName(
    LocalListByStudentNameRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byStudentName,
      status: event.status,
      academicYearId: event.academicYearId,
      enrollmentType: event.enrollmentType,
      page: event.page,
      size: event.size,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
    ),
  );

  Future<void> _onByStudentNamesAndDateOfBirth(
    LocalListByStudentNamesAndDateOfBirthRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byStudentNamesAndDateOfBirth,
      status: event.status,
      academicYearId: event.academicYearId,
      enrollmentType: event.enrollmentType,
      page: event.page,
      size: event.size,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      dateOfBirth: event.dateOfBirth,
    ),
  );

  Future<void> _onByDateOfBirth(
    LocalListByDateOfBirthRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byDateOfBirth,
      status: event.status,
      academicYearId: event.academicYearId,
      enrollmentType: event.enrollmentType,
      page: event.page,
      size: event.size,
      dateOfBirth: event.dateOfBirth,
    ),
  );

  Future<void> _onByAcademicInfo(
    LocalListByAcademicInfoRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byAcademicInfo,
      status: '',
      academicYearId: '',
      page: event.page,
      size: event.size,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      schoolLevelGroupId: event.schoolLevelGroupId,
      schoolLevelId: event.schoolLevelId,
    ),
  );

  Future<void> _onByPreEnrollmentAcademicInfo(
    LocalListByPreEnrollmentAcademicInfoRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byAcademicInfo,
      academicInfoSource: AcademicInfoSource.preEnrollmentCohort,
      status: '',
      academicYearId: '',
      page: event.page,
      size: event.size,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      schoolLevelGroupId: event.schoolLevelGroupId,
      schoolLevelId: event.schoolLevelId,
    ),
  );

  Future<void> _onByEnrolledAcademicInfo(
    LocalListByEnrolledAcademicInfoRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byAcademicInfo,
      academicInfoSource: AcademicInfoSource.currentYearEnrolled,
      status: '',
      academicYearId: event.academicYearId,
      page: event.page,
      size: event.size,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      schoolLevelGroupId: event.schoolLevelGroupId,
      schoolLevelId: event.schoolLevelId,
    ),
  );

  Future<void> _onByAcademicInfoAndStatus(
    LocalListByAcademicInfoAndStatusRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) => _load(
    emit,
    EnrollmentSummariesQuery(
      type: EnrollmentSummaryQueryType.byAcademicInfo,
      academicInfoSource: AcademicInfoSource.currentYearByStatus,
      status: event.status,
      academicYearId: event.academicYearId,
      enrollmentType: event.enrollmentType,
      page: event.page,
      size: event.size,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      schoolLevelGroupId: event.schoolLevelGroupId,
      schoolLevelId: event.schoolLevelId,
    ),
  );

  /// Lit la base locale adaptée au type de requête, raffine/pagine côté client,
  /// met en cache la liste filtrée complète et émet la page demandée.
  Future<void> _load(
    Emitter<EnrollmentLocalListState> emit,
    EnrollmentSummariesQuery query,
  ) async {
    final generation = ++_loadGeneration;
    emit(
      state.copyWith(
        summariesStatus: EnrollmentLoadStatus.loading,
        summariesQueryType: query.type,
        lastSummariesQuery: query,
        summariesErrorType: null,
        errorMessage: null,
      ),
    );

    // Chaque branche produit directement la liste de résumés PROJETÉE (raffinée
    // nom/DOB), pour un `fold` uniforme malgré des sources différentes :
    //  - byAcademicInfo / réinscription : vivier N-1 (cohorte) ∪ dossiers locaux
    //    de l'année courante, superposés/dédupliqués par `studentId` ;
    //  - byAcademicInfo / Facturation : élèves réellement inscrits l'année
    //    courante (dossiers finalisés SYNCED|PENDING_SYNC|SYNC_ERROR) ;
    //  - autres : liste `enrollments` scopée statut + année (parité online).
    final Either<Failure, List<EnrollmentSummary>> projectedResult = switch ((
      query.type,
      query.academicInfoSource,
    )) {
      (
        EnrollmentSummaryQueryType.byAcademicInfo,
        AcademicInfoSource.reenrollmentCohort,
      ) =>
        (await _search.byCohort(
          schoolLevelGroupId: _nullIfEmpty(query.schoolLevelGroupId),
          schoolLevelId: _nullIfEmpty(query.schoolLevelId),
        )).map(
          (r) => EnrollmentLocalListProjector.projectReenrollment(
            candidates: r.candidates,
            localDossiers: r.localDossiers,
            firstName: query.firstName,
            lastName: query.lastName,
            surname: query.surname,
            dateOfBirth: query.dateOfBirth,
          ),
        ),
      (
        EnrollmentSummaryQueryType.byAcademicInfo,
        AcademicInfoSource.preEnrollmentCohort,
      ) =>
        (await _search.byPreEnrollmentCohort(
          schoolLevelGroupId: _nullIfEmpty(query.schoolLevelGroupId),
          schoolLevelId: _nullIfEmpty(query.schoolLevelId),
        )).map(
          (r) => EnrollmentLocalListProjector.projectPreEnrollment(
            candidates: r.candidates,
            localDossiers: r.localDossiers,
            firstName: query.firstName,
            lastName: query.lastName,
            surname: query.surname,
            dateOfBirth: query.dateOfBirth,
          ),
        ),
      (
        EnrollmentSummaryQueryType.byAcademicInfo,
        AcademicInfoSource.currentYearEnrolled,
      ) =>
        (await _search.currentYearEnrolled(
          academicYearId: _nullIfEmpty(query.academicYearId),
          schoolLevelGroupId: _nullIfEmpty(query.schoolLevelGroupId),
          schoolLevelId: _nullIfEmpty(query.schoolLevelId),
        )).map(
          (items) => EnrollmentLocalListProjector.project(
            items,
            firstName: query.firstName,
            lastName: query.lastName,
            surname: query.surname,
            dateOfBirth: query.dateOfBirth,
          ),
        ),
      (
        EnrollmentSummaryQueryType.byAcademicInfo,
        AcademicInfoSource.currentYearByStatus,
      ) =>
        (await _search.byAcademicInfo(
          status: _nullIfEmpty(query.status),
          academicYearId: _nullIfEmpty(query.academicYearId),
          schoolLevelGroupId: _nullIfEmpty(query.schoolLevelGroupId),
          schoolLevelId: _nullIfEmpty(query.schoolLevelId),
          enrollmentType: query.enrollmentType,
        )).map(
          (items) => EnrollmentLocalListProjector.project(
            items,
            firstName: query.firstName,
            lastName: query.lastName,
            surname: query.surname,
            dateOfBirth: query.dateOfBirth,
          ),
        ),
      _ =>
        (await _getEnrollments(
          status: _nullIfEmpty(query.status),
          academicYearId: _nullIfEmpty(query.academicYearId),
          enrollmentType: query.enrollmentType,
        )).map(
          (items) => EnrollmentLocalListProjector.project(
            items,
            firstName: query.firstName,
            lastName: query.lastName,
            surname: query.surname,
            dateOfBirth: query.dateOfBirth,
          ),
        ),
    };

    // Une requête plus récente a pris la main pendant nos awaits : on abandonne
    // ce résultat périmé (ni cache ni emit) — la génération courante gagnera.
    if (generation != _loadGeneration) return;

    projectedResult.fold(
      (failure) {
        // Purge le cache ET la liste d'état : l'écran d'erreur partagé remplace
        // la liste, donc l'état ne doit pas conserver l'ancienne liste (sinon
        // une pagination ou un rebuild ressortirait des données périmées sous
        // l'identité de la requête échouée).
        _cache = const <EnrollmentSummary>[];
        emit(
          state.copyWith(
            summariesStatus: EnrollmentLoadStatus.failure,
            summaries: const <EnrollmentSummary>[],
            summariesTotalElements: 0,
            summariesTotalPages: 0,
            summariesErrorType: _mapFailureToErrorType(failure),
            errorMessage: failure.message,
          ),
        );
      },
      (projected) {
        _cache = projected;
        final pageData = EnrollmentLocalListProjector.paginate(
          projected,
          page: query.page,
          size: query.size,
        );
        emit(_successState(query.copyWithPage(pageData.page), pageData));
      },
    );
  }

  EnrollmentLocalListState _successState(
    EnrollmentSummariesQuery query,
    EnrollmentLocalPage page,
  ) {
    return state.copyWith(
      summariesStatus: EnrollmentLoadStatus.success,
      summaries: page.content,
      summariesPage: page.page,
      summariesSize: page.size,
      summariesTotalElements: page.totalElements,
      summariesTotalPages: page.totalPages,
      summariesQueryType: query.type,
      lastSummariesQuery: query,
      summariesErrorType: null,
      errorMessage: null,
    );
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Les échecs sont ici locaux (accès sqflite) : on les présente via le type
  /// d'erreur générique « serveur » des états partagés (jamais réseau/401/403).
  EnrollmentErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => EnrollmentErrorType.network,
      StorageFailure() => EnrollmentErrorType.server,
      _ => EnrollmentErrorType.unknown,
    };
  }
}
