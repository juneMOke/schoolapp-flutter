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
  }

  void _onReset(
    LocalListResetRequested event,
    Emitter<EnrollmentLocalListState> emit,
  ) {
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

  /// Lit la base locale adaptée au type de requête, raffine/pagine côté client,
  /// met en cache la liste filtrée complète et émet la page demandée.
  Future<void> _load(
    Emitter<EnrollmentLocalListState> emit,
    EnrollmentSummariesQuery query,
  ) async {
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
    //  - byAcademicInfo (RÉINSCRIPTION) : vivier N-1 (cohorte) ∪ dossiers locaux
    //    de l'année courante, superposés/dédupliqués par `studentId` ;
    //  - autres : liste `enrollments` scopée statut + année (parité online).
    final Either<Failure, List<EnrollmentSummary>> projectedResult =
        switch (query.type) {
          EnrollmentSummaryQueryType.byAcademicInfo =>
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

    projectedResult.fold(
      (failure) {
        // Purge le cache : l'identité de requête (lastSummariesQuery/queryType)
        // a basculé sur la requête échouée ; laisser l'ancienne liste en cache
        // permettrait à une pagination de ré-émettre des données périmées.
        _cache = const <EnrollmentSummary>[];
        emit(
          state.copyWith(
            summariesStatus: EnrollmentLoadStatus.failure,
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
