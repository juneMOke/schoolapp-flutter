import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/client_side_paginator.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_projector.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_charge_aggregates_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_tariffs_for_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/has_fee_grid_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_projector.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_tariffs_resolver.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';

// Un seul import suffit aux widgets du Contrôle des frais pour l'état, le
// statut de chargement et les contrats de recherche.
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
// `FeeControlBreakdown` fait partie de la surface publique de l'état (bandeau
// de synthèse), même si son calcul vit dans le projecteur.
export 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_projector.dart'
    show FeeControlBreakdown;
export 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';

part 'fee_control_event.dart';
part 'fee_control_state.dart';

/// BLoC du **Contrôle des frais** : pour un frais donné d'une classe donnée,
/// qui est soldé, qui est partiel, qui n'a rien versé.
///
/// Bloc **dédié**, et non un mode de plus sur `EnrollmentLocalListBloc` : ce
/// dernier est partagé par la Facturation et les Documents, et y ajouter des
/// critères financiers y ferait entrer un domaine qui n'est pas le sien.
///
/// Lecture **100 % locale**, en deux temps :
///  1. les élèves réellement inscrits de la classe
///     (`SearchLocalEnrollmentsUseCase.currentYearEnrolled` — mêmes règles de
///     « facturable » que la Facturation), raffinés nom/post-nom/prénom par
///     [EnrollmentLocalListProjector] ;
///  2. leur position sur le frais, agrégée par le grand-livre local.
///
/// Le périmètre se resserre en trois crans : le niveau (obligatoire), puis
/// éventuellement **une classe** — le roster local composé donne alors les
/// élèves retenus — puis le raffinement par nom.
///
/// Un élève **sans créance** de ce frais est écarté : « aucun paiement » n'est
/// pas « aucune créance ». L'écart entre [FeeControlState.studentsInScope] et
/// `breakdown.total` permet à l'état vide de le dire.
class FeeControlBloc extends Bloc<FeeControlEvent, FeeControlState> {
  final SearchLocalEnrollmentsUseCase _search;
  final GetFeeChargeAggregatesUseCase _getAggregates;
  final FeeControlTariffsResolver _tariffs;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetOfflineRosterUseCase _getRoster;

  /// Liste complète filtrée de la recherche courante, conservée pour paginer
  /// sans relire la base.
  List<FeeControlRow> _cache = const <FeeControlRow>[];

  // Générations de chargement : le transformer par défaut du bloc étant
  // `concurrent`, plusieurs chargements peuvent voler en parallèle. Chaque
  // chargement capture le numéro courant ; seul le PLUS RÉCENT écrit et émet
  // (sémantique restartable) — une recherche périmée résolue en dernier ne peut
  // plus repeindre la liste sous une identité de requête plus fraîche.
  int _loadGeneration = 0;
  int _tariffsGeneration = 0;
  int _classroomsGeneration = 0;

  FeeControlBloc({
    required SearchLocalEnrollmentsUseCase search,
    required GetFeeChargeAggregatesUseCase getAggregates,
    required GetFeeTariffsForLevelUseCase getTariffs,
    required HasFeeGridUseCase hasFeeGrid,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetOfflineRosterUseCase getRoster,
  }) : _search = search,
       _getAggregates = getAggregates,
       _tariffs = FeeControlTariffsResolver(
         getTariffs: getTariffs,
         hasFeeGrid: hasFeeGrid,
       ),
       _getClassrooms = getClassrooms,
       _getRoster = getRoster,
       super(const FeeControlState.initial()) {
    on<FeeControlTariffsRequested>(_onTariffsRequested);
    on<FeeControlClassroomsRequested>(_onClassroomsRequested);
    on<FeeControlSearchRequested>(_onSearchRequested);
    on<FeeControlPageRequested>(_onPageRequested);
    on<FeeControlRefreshRequested>(_onRefreshRequested);
    on<FeeControlResetRequested>(_onResetRequested);
  }

  // ── Grille tarifaire ────────────────────────────────────────────────────────

  Future<void> _onTariffsRequested(
    FeeControlTariffsRequested event,
    Emitter<FeeControlState> emit,
  ) async {
    final generation = ++_tariffsGeneration;
    emit(
      state.copyWith(
        tariffsStatus: EnrollmentLoadStatus.loading,
        tariffs: const <LocalFeeTariff>[],
        feeGridMissing: false,
      ),
    );

    final outcome = await _tariffs.resolve(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
      schoolLevelGroupId: _nullIfEmpty(event.schoolLevelGroupId),
    );
    if (generation != _tariffsGeneration) return;

    emit(
      state.copyWith(
        tariffsStatus: outcome.failed
            ? EnrollmentLoadStatus.failure
            : EnrollmentLoadStatus.success,
        tariffs: outcome.tariffs,
        feeGridMissing: outcome.gridMissing,
      ),
    );
  }

  // ── Classes du niveau ──────────────────────────────────────────────────────

  Future<void> _onClassroomsRequested(
    FeeControlClassroomsRequested event,
    Emitter<FeeControlState> emit,
  ) async {
    final generation = ++_classroomsGeneration;
    emit(
      state.copyWith(
        classroomsStatus: EnrollmentLoadStatus.loading,
        classrooms: const <OfflineClassroom>[],
      ),
    );

    final result = await _getClassrooms(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
    );
    if (generation != _classroomsGeneration) return;

    emit(
      result.fold(
        (_) => state.copyWith(
          classroomsStatus: EnrollmentLoadStatus.failure,
          classrooms: const <OfflineClassroom>[],
        ),
        (classrooms) => state.copyWith(
          classroomsStatus: EnrollmentLoadStatus.success,
          classrooms: classrooms,
        ),
      ),
    );
  }

  // ── Recherche ──────────────────────────────────────────────────────────────

  Future<void> _onSearchRequested(
    FeeControlSearchRequested event,
    Emitter<FeeControlState> emit,
  ) {
    final request = event.request;
    return _load(
      emit,
      FeeControlQuery(
        academicYearId: event.academicYearId,
        schoolLevelGroupId: request.schoolLevelGroupId,
        schoolLevelId: request.schoolLevelId,
        classroomId: request.classroomId,
        feeCode: request.feeCode,
        statusFilter: request.statusFilter,
        firstName: request.firstName,
        lastName: request.lastName,
        surname: request.surname,
        page: event.page,
        size: event.size,
      ),
    );
  }

  Future<void> _onRefreshRequested(
    FeeControlRefreshRequested event,
    Emitter<FeeControlState> emit,
  ) async {
    final last = state.lastQuery;
    if (last == null) return;
    await _load(emit, last);
  }

  void _onPageRequested(
    FeeControlPageRequested event,
    Emitter<FeeControlState> emit,
  ) {
    final last = state.lastQuery;
    if (last == null) return;
    // Pagination seulement sur une liste settled : pendant un chargement en vol,
    // `_cache` peut encore appartenir à la requête précédente (on paginerait
    // alors des données périmées sous la nouvelle identité de requête).
    if (state.status != EnrollmentLoadStatus.success) return;

    final maxPage = state.totalPages > 0 ? state.totalPages - 1 : 0;
    final nextPage = event.page.clamp(0, maxPage);
    emit(
      state.withPage(
        query: last,
        page: ClientSidePaginator.paginate(
          _cache,
          page: nextPage,
          size: last.size,
        ),
      ),
    );
  }

  void _onResetRequested(
    FeeControlResetRequested event,
    Emitter<FeeControlState> emit,
  ) {
    _loadGeneration++; // invalide tout chargement en vol
    _cache = const <FeeControlRow>[];
    emit(const FeeControlState.initial());
  }

  Future<void> _load(
    Emitter<FeeControlState> emit,
    FeeControlQuery query,
  ) async {
    final generation = ++_loadGeneration;
    emit(
      state.copyWith(
        status: EnrollmentLoadStatus.loading,
        lastQuery: query,
        errorType: null,
        errorMessage: null,
      ),
    );

    final enrolled = await _search.currentYearEnrolled(
      academicYearId: _nullIfEmpty(query.academicYearId),
      schoolLevelGroupId: _nullIfEmpty(query.schoolLevelGroupId),
      schoolLevelId: _nullIfEmpty(query.schoolLevelId),
    );
    if (generation != _loadGeneration) return;

    // Maille classe : le roster local COMPOSÉ (miroir ± transferts non
    // synchronisés) donne les élèves retenus. Lu avant le raffinement par nom,
    // pour que « élèves du niveau » devienne « élèves de la classe » avant
    // toute autre coupe. Une classe vide localement (roster pas encore pullé)
    // donne un ensemble vide — l'écran le dit plutôt que de retomber
    // silencieusement sur le niveau entier.
    Set<String>? classroomStudentIds;
    if (query.classroomId != null) {
      final roster = await _getRoster(classroomId: query.classroomId!);
      if (generation != _loadGeneration) return;
      final failed = roster.fold(
        (failure) {
          _emitFailure(emit, failure);
          return true;
        },
        (members) {
          classroomStudentIds = members.map((m) => m.studentId).toSet();
          return false;
        },
      );
      if (failed) return;
    }

    await enrolled.fold((failure) async => _emitFailure(emit, failure), (
      items,
    ) async {
      final scoped = classroomStudentIds == null
          ? items
          : items
                .where((i) => classroomStudentIds!.contains(i.studentId))
                .toList(growable: false);
      final summaries = EnrollmentLocalListProjector.project(
        scoped,
        firstName: query.firstName,
        lastName: query.lastName,
        surname: query.surname,
      );
      if (summaries.isEmpty) {
        _cache = const <FeeControlRow>[];
        emit(
          state.withPage(
            query: query,
            page: ClientSidePaginator.paginate(
              const <FeeControlRow>[],
              page: 0,
              size: query.size,
            ),
            studentsInScope: 0,
            breakdown: const FeeControlBreakdown(),
            classroomRosterSize: classroomStudentIds?.length,
          ),
        );
        return;
      }

      final aggregates = await _getAggregates(
        academicYearId: query.academicYearId,
        feeCode: query.feeCode,
        studentIds: summaries.map((s) => s.student.id).toList(growable: false),
      );
      if (generation != _loadGeneration) return;

      aggregates.fold((failure) => _emitFailure(emit, failure), (list) {
        final join = FeeControlProjector.join(
          summaries: summaries,
          aggregates: list,
          filter: query.statusFilter,
        );
        _cache = join.filtered;
        emit(
          state.withPage(
            query: query,
            page: ClientSidePaginator.paginate(
              join.filtered,
              page: query.page,
              size: query.size,
            ),
            studentsInScope: summaries.length,
            breakdown: join.breakdown,
            classroomRosterSize: classroomStudentIds?.length,
          ),
        );
      });
    });
  }

  /// Purge aussi le cache : l'écran d'erreur remplace la liste, et une
  /// pagination ou un rebuild ne doit pas ressortir des données périmées sous
  /// l'identité de la requête échouée.
  void _emitFailure(Emitter<FeeControlState> emit, Failure failure) {
    _cache = const <FeeControlRow>[];
    emit(
      state.withFailure(
        errorType: _mapFailureToErrorType(failure),
        errorMessage: failure.message,
      ),
    );
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Les échecs sont ici locaux (accès sqflite) : on les présente via le type
  /// d'erreur générique « serveur » des états partagés (jamais réseau/401/403).
  static EnrollmentErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => EnrollmentErrorType.network,
      StorageFailure() => EnrollmentErrorType.server,
      _ => EnrollmentErrorType.unknown,
    };
  }
}
