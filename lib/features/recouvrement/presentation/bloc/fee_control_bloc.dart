import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/client_side_paginator.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_projector.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_natures_for_year_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

// Un seul import suffit aux widgets du Contrôle des frais pour l'état, le
// statut de chargement et les contrats de recherche.
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
// `FeeControlBreakdown` fait partie de la surface publique de l'état (bandeau
// de synthèse), même si son calcul vit dans le projecteur.
export 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart'
    show FeeControlBreakdown;
export 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

part 'fee_control_event.dart';
part 'fee_control_state.dart';

/// BLoC du **Contrôle des frais** (spec Recouvrement v2, page 2) : pour une
/// **sélection de frais** et une classe — ou la rubrique « Non affectés » —,
/// qui est soldé, qui est partiel, qui n'a rien versé.
///
/// Lecture **100 % locale** (arbitrage du 2026-11-21 : le contrôle reste hors
/// ligne), en deux temps :
///  1. les élèves réellement inscrits de l'année
///     (`SearchLocalEnrollmentsUseCase.currentYearEnrolled`, désactivés exclus
///     comme au serveur), ramenés à la classe par son roster local COMPOSÉ —
///     ou, pour « Non affectés », privés de tous les élèves d'un roster ;
///  2. leur position sur les frais retenus (`GetRecoveryPositionsUseCase`),
///     lue avec l'arithmétique partagée avec le serveur (`RecoveryStanding`).
///
/// **Aucune conversion de devise** : le cours du jour n'entre plus ici. En
/// sélection mixte, « a payé au moins… » est indisponible et le tri suit la
/// situation.
///
/// Un élève **sans créance** de ces frais est écarté : « aucun paiement » n'est
/// pas « aucune créance ».
class FeeControlBloc extends Bloc<FeeControlEvent, FeeControlState> {
  final SearchLocalEnrollmentsUseCase _search;
  final GetRecoveryPositionsUseCase _getPositions;
  final GetFeeNaturesForYearUseCase _getNatures;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetOfflineRosterUseCase _getRoster;
  final GetComposedRostersUseCase _getComposedRosters;

  /// Liste complète filtrée de la recherche courante, conservée pour paginer
  /// sans relire la base.
  List<FeeControlRow> _cache = const <FeeControlRow>[];

  /// Toute la population **concernée**, avant la coupe par situation. C'est
  /// elle que les tuiles de compteur recoupent, sans relire.
  List<FeeControlRow> _charged = const <FeeControlRow>[];

  /// Le résultat **entier**, dans l'ordre où l'écran le sert — la sélection
  /// et les exports portent sur tout le résultat, pas sur la page affichée.
  List<FeeControlRow> get results => List.unmodifiable(_cache);

  // Générations de chargement (transformer `concurrent`) : seul le PLUS RÉCENT
  // écrit et émet.
  int _loadGeneration = 0;
  int _catalogGeneration = 0;

  FeeControlBloc({
    required SearchLocalEnrollmentsUseCase search,
    required GetRecoveryPositionsUseCase getPositions,
    required GetFeeNaturesForYearUseCase getNatures,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetOfflineRosterUseCase getRoster,
    required GetComposedRostersUseCase getComposedRosters,
  }) : _search = search,
       _getPositions = getPositions,
       _getNatures = getNatures,
       _getClassrooms = getClassrooms,
       _getRoster = getRoster,
       _getComposedRosters = getComposedRosters,
       super(const FeeControlState.initial()) {
    on<FeeControlCatalogRequested>(_onCatalogRequested);
    on<FeeControlSearchRequested>(_onSearchRequested);
    on<FeeControlSituationRequested>(_onSituationRequested);
    on<FeeControlPageRequested>(_onPageRequested);
    on<FeeControlRefreshRequested>(_onRefreshRequested);
    on<FeeControlResetRequested>(_onResetRequested);
  }

  // ── Catalogue ──────────────────────────────────────────────────────────────

  Future<void> _onCatalogRequested(
    FeeControlCatalogRequested event,
    Emitter<FeeControlState> emit,
  ) async {
    final generation = ++_catalogGeneration;
    emit(state.copyWith(catalogStatus: EnrollmentLoadStatus.loading));
    final natures = await _getNatures(academicYearId: event.academicYearId);
    if (generation != _catalogGeneration) return;
    final classrooms = await _getClassrooms(
      academicYearId: event.academicYearId,
    );
    if (generation != _catalogGeneration) return;

    final next = natures.fold<FeeControlState?>(
      (_) => null,
      (list) => classrooms.fold(
        (_) => null,
        (rooms) => state.copyWith(
          catalogStatus: EnrollmentLoadStatus.success,
          natures: [
            for (final n in list)
              FeeNature(feeCode: n.feeCode, currencies: n.currencies),
          ],
          classrooms: rooms,
        ),
      ),
    );
    emit(next ?? state.copyWith(catalogStatus: EnrollmentLoadStatus.failure));
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
        classroomId: request.classroomId,
        feeCodes: request.feeCodes,
        statusFilter: request.statusFilter,
        threshold: request.threshold,
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

  /// Recoupe la population déjà lue. Ne touche ni aux compteurs ni à
  /// l'encaissé : ils portent sur la classe entière, et une tuile qui
  /// changerait le total qu'elle affiche n'afficherait que son propre reflet.
  void _onSituationRequested(
    FeeControlSituationRequested event,
    Emitter<FeeControlState> emit,
  ) {
    final last = state.lastQuery;
    if (last == null) return;
    if (state.status != EnrollmentLoadStatus.success) return;
    final query = last.copyWithSituation(
      event.filter,
      threshold: event.threshold,
    );
    if (query == last.copyWithPage(0)) return;

    _cache = FeeControlProjector.refilter(
      _charged,
      filter: query.statusFilter,
      threshold: query.threshold,
      mixed: state.currencies.length > 1,
    );
    emit(
      state.withPage(
        query: query,
        page: ClientSidePaginator.paginate(_cache, page: 0, size: query.size),
      ),
    );
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
    _charged = const <FeeControlRow>[];
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
    );
    if (generation != _loadGeneration) return;

    // Le périmètre : le roster local COMPOSÉ de la classe (miroir ± transferts
    // non synchronisés) ; pour « Non affectés », tous les inscrits privés des
    // élèves d'un roster de l'année. Une classe vide localement donne un
    // ensemble vide — l'écran le dit plutôt que de retomber sur l'année.
    Set<String>? classroomStudentIds;
    Set<String>? assignedStudentIds;
    final failure = query.isUnassigned
        ? await _assigned(
            query.academicYearId,
            (ids) => assignedStudentIds = ids,
          )
        : await _roster(query.classroomId, (ids) => classroomStudentIds = ids);
    if (generation != _loadGeneration) return;
    if (failure != null) {
      _emitFailure(emit, failure);
      return;
    }

    await enrolled.fold((failure) async => _emitFailure(emit, failure), (
      items,
    ) async {
      final scoped = [
        for (final i in items)
          if (classroomStudentIds?.contains(i.studentId) ??
              !(assignedStudentIds?.contains(i.studentId) ?? false))
            i,
      ];
      final summaries = EnrollmentLocalListProjector.project(scoped);
      if (summaries.isEmpty) {
        _cache = const <FeeControlRow>[];
        _charged = const <FeeControlRow>[];
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
            expected: MoneyBag.empty,
            collected: MoneyBag.empty,
            currencies: const <String>{},
            classroomRosterSize: classroomStudentIds?.length,
          ),
        );
        return;
      }

      final positions = await _getPositions(
        academicYearId: query.academicYearId,
        feeCodes: query.feeCodes,
      );
      if (generation != _loadGeneration) return;

      positions.fold((failure) => _emitFailure(emit, failure), (lines) {
        final join = FeeControlProjector.join(
          summaries: summaries,
          lines: lines,
          filter: query.statusFilter,
          threshold: query.threshold,
        );
        _cache = join.filtered;
        _charged = join.charged;
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
            expected: join.expected,
            collected: join.collected,
            currencies: join.currencies,
            classroomRosterSize: classroomStudentIds?.length,
          ),
        );
      });
    });
  }

  /// Les élèves du roster composé de [classroomId] ; rend l'échec, ou `null`.
  Future<Failure?> _roster(
    String classroomId,
    void Function(Set<String>) onIds,
  ) async {
    final roster = await _getRoster(classroomId: classroomId);
    return roster.fold((failure) => failure, (members) {
      onIds({for (final m in members) m.studentId});
      return null;
    });
  }

  /// Tous les élèves d'un roster de l'année — ce que « Non affectés » retire.
  /// Un roster par niveau ayant des classes : une vingtaine de lectures au
  /// plus, sur une base locale.
  Future<Failure?> _assigned(
    String academicYearId,
    void Function(Set<String>) onIds,
  ) async {
    final rooms = await _getClassrooms(academicYearId: academicYearId);
    final levels = rooms.fold<Set<String>?>(
      (_) => null,
      (list) => {
        for (final c in list)
          if (c.schoolLevelId != null) c.schoolLevelId!,
      },
    );
    if (levels == null) {
      return rooms.fold((failure) => failure, (_) => null);
    }
    final ids = <String>{};
    for (final level in levels) {
      final rosters = await _getComposedRosters(
        academicYearId: academicYearId,
        schoolLevelId: level,
      );
      final failure = rosters.fold<Failure?>((f) => f, (byClass) {
        for (final members in byClass.values) {
          ids.addAll(members.map((m) => m.studentId));
        }
        return null;
      });
      if (failure != null) return failure;
    }
    onIds(ids);
    return null;
  }

  /// Purge aussi le cache : l'écran d'erreur remplace la liste, et une
  /// pagination ou un rebuild ne doit pas ressortir des données périmées sous
  /// l'identité de la requête échouée.
  void _emitFailure(Emitter<FeeControlState> emit, Failure failure) {
    _cache = const <FeeControlRow>[];
    _charged = const <FeeControlRow>[];
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
