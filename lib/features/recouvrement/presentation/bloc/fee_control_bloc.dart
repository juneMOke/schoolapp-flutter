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
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_tariffs_for_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/has_fee_grid_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_tariffs_resolver.dart';
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

/// BLoC du **Contrôle des frais** : pour une **sélection de frais** et une
/// classe donnée, qui est soldé, qui est partiel, qui n'a rien versé.
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
///  2. leur position sur les frais retenus, lue dans le **même registre** que
///     le tableau de bord (`GetRecoveryPositionsUseCase`) — c'est ce qui rend
///     impossible que les deux écrans se contredisent sur le même élève.
///
/// Le périmètre se resserre en deux crans : le niveau (obligatoire), puis
/// éventuellement **une classe** — le roster local composé donne alors les
/// élèves retenus.
///
/// ⚠️ La lecture du registre n'est **pas** bornée au cycle, alors qu'elle
/// pourrait l'être : un élève qui a changé de niveau en cours d'année porte des
/// créances sur les deux, et il les doit toutes. Les borner au cycle de sa
/// classe actuelle ferait disparaître une dette de la feuille que son parent
/// signe.
///
/// Un élève **sans créance** de ces frais est écarté : « aucun paiement » n'est
/// pas « aucune créance ». L'écart entre [FeeControlState.studentsInScope] et
/// `breakdown.total` permet à l'état vide de le dire.
class FeeControlBloc extends Bloc<FeeControlEvent, FeeControlState> {
  final SearchLocalEnrollmentsUseCase _search;
  final GetRecoveryPositionsUseCase _getPositions;
  final FeeControlTariffsResolver _tariffs;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetOfflineRosterUseCase _getRoster;

  /// Liste complète filtrée de la recherche courante, conservée pour paginer
  /// sans relire la base.
  List<FeeControlRow> _cache = const <FeeControlRow>[];

  /// Toute la population **concernée**, avant la coupe par situation. C'est
  /// elle que les tuiles de compteur recoupent, sans relire.
  List<FeeControlRow> _charged = const <FeeControlRow>[];

  /// Le résultat **entier**, dans l'ordre où l'écran le sert — pas seulement la
  /// page affichée.
  ///
  /// Exposé parce que la sélection porte sur tout le résultat : la feuille
  /// d'appel doit pouvoir nommer un élève coché à la page 1 alors qu'on en est
  /// à la page 3. L'ordre est celui du tri, donc celui de la numérotation
  /// imprimée.
  List<FeeControlRow> get results => List.unmodifiable(_cache);

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
    required GetRecoveryPositionsUseCase getPositions,
    required GetFeeTariffsForLevelUseCase getTariffs,
    required HasFeeGridUseCase hasFeeGrid,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetOfflineRosterUseCase getRoster,
  }) : _search = search,
       _getPositions = getPositions,
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
    on<FeeControlSituationRequested>(_onSituationRequested);
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
        feeCodes: request.feeCodes,
        statusFilter: request.statusFilter,
        threshold: request.threshold,
        rate: event.rate,
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
    if (last.statusFilter == event.filter) return;

    final query = last.copyWithSituation(event.filter);
    _cache = FeeControlProjector.refilter(
      _charged,
      filter: query.statusFilter,
      threshold: query.threshold,
      rate: query.rate,
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
          rate: query.rate,
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
