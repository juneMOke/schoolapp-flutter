import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_class_projector.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_projector.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_dashboard_contracts.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_charge_positions_by_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_codes_for_year_use_case.dart';

// Un seul import suffit aux widgets du tableau de bord.
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
export 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
export 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_class_projector.dart'
    show FeeControlClassRow;
export 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_projector.dart'
    show FeeControlDashboardSummary, FeeControlGroupRow;
export 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_dashboard_contracts.dart';

part 'fee_control_dashboard_event.dart';
part 'fee_control_dashboard_state.dart';

/// BLoC du **tableau de bord** du Contrôle des frais : pour un frais donné,
/// quelle part des élèves est en ordre, et quels groupes décrochent.
///
/// Lecture **100 % locale**, en deux temps indépendants : les natures de frais
/// facturées sur l'année, puis la position de toute la population sur celle
/// qu'on interroge. Aucune écriture — cet écran regarde, il n'encaisse pas.
///
/// Il ne recompte rien lui-même : le grand-livre rend les positions,
/// [FeeControlDashboardProjector] les ventile, et le statut d'un élève reste
/// celui de `LocalFeeChargeAggregate` — la règle de l'écran de contrôle. C'est
/// ce qui interdit aux deux écrans du module de se contredire.
///
/// **Le cycle n'est pas chargé ici** : la liste des cycles vient du contexte
/// académique (`AcademicYearContextBloc`), que la page a déjà sous la main.
class FeeControlDashboardBloc
    extends Bloc<FeeControlDashboardEvent, FeeControlDashboardState> {
  final GetFeeCodesForYearUseCase _getFeeCodes;
  final GetFeeChargePositionsByLevelUseCase _getPositions;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetComposedRostersUseCase _getRosters;
  final SearchLocalEnrollmentsUseCase _searchEnrollments;

  /// Positions de la dernière lecture, gardées **hors de l'état**.
  ///
  /// Déplier un niveau n'est qu'une répartition de ces élèves-là : les
  /// reconserver dans l'état alourdirait chaque comparaison d'`Equatable` de
  /// plusieurs centaines d'objets, à chaque `buildWhen`, pour une donnée que
  /// l'écran ne rend jamais telle quelle.
  List<LocalFeeLevelAggregate> _positions = const <LocalFeeLevelAggregate>[];

  // Générations de chargement : le transformer par défaut du bloc étant
  // `concurrent`, deux lectures peuvent voler en parallèle — changer de frais
  // deux fois de suite suffit. Chaque lecture capture le numéro courant ; seule
  // la PLUS RÉCENTE écrit et émet. Sans cela, une lecture périmée résolue en
  // dernier repeindrait le classement sous le nom d'un autre frais.
  int _feeCodesGeneration = 0;
  int _loadGeneration = 0;
  int _classesGeneration = 0;

  FeeControlDashboardBloc({
    required GetFeeCodesForYearUseCase getFeeCodes,
    required GetFeeChargePositionsByLevelUseCase getPositions,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetComposedRostersUseCase getRosters,
    required SearchLocalEnrollmentsUseCase searchEnrollments,
  }) : _getFeeCodes = getFeeCodes,
       _getPositions = getPositions,
       _getClassrooms = getClassrooms,
       _getRosters = getRosters,
       _searchEnrollments = searchEnrollments,
       super(const FeeControlDashboardState.initial()) {
    on<FeeControlDashboardFeeCodesRequested>(_onFeeCodesRequested);
    on<FeeControlDashboardRequested>(_onRequested);
    on<FeeControlDashboardRefreshRequested>(_onRefreshRequested);
    on<FeeControlDashboardGroupToggled>(_onGroupToggled);
  }

  // ── Natures de frais ────────────────────────────────────────────────────────

  Future<void> _onFeeCodesRequested(
    FeeControlDashboardFeeCodesRequested event,
    Emitter<FeeControlDashboardState> emit,
  ) async {
    final generation = ++_feeCodesGeneration;
    emit(
      state.copyWith(
        feeCodesStatus: EnrollmentLoadStatus.loading,
        feeCodes: const <String>[],
      ),
    );

    final outcome = await _getFeeCodes(academicYearId: event.academicYearId);
    if (generation != _feeCodesGeneration) return;

    emit(
      outcome.fold(
        (failure) => state.copyWith(
          feeCodesStatus: EnrollmentLoadStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: failure.message,
        ),
        (codes) => state.copyWith(
          feeCodesStatus: EnrollmentLoadStatus.success,
          feeCodes: codes,
        ),
      ),
    );
  }

  // ── Position de la population ───────────────────────────────────────────────

  Future<void> _onRequested(
    FeeControlDashboardRequested event,
    Emitter<FeeControlDashboardState> emit,
  ) => _load(
    FeeControlDashboardQuery(
      academicYearId: event.academicYearId,
      feeCode: event.feeCode,
      schoolLevelGroupId: _nullIfEmpty(event.schoolLevelGroupId),
    ),
    emit,
  );

  /// Rejoue la dernière lecture. Sans `lastQuery`, ne fait **rien** : une
  /// reprise qui interrogerait autre chose que ce qui a échoué mentirait sur ce
  /// qu'elle répare.
  Future<void> _onRefreshRequested(
    FeeControlDashboardRefreshRequested event,
    Emitter<FeeControlDashboardState> emit,
  ) async {
    final query = state.lastQuery;
    if (query == null) return;
    await _load(query, emit);
  }

  Future<void> _load(
    FeeControlDashboardQuery query,
    Emitter<FeeControlDashboardState> emit,
  ) async {
    final generation = ++_loadGeneration;
    // Un dépliage EN VOL est annulé avec la lecture qu'il détaillait : il lit
    // `_positions`, que celle-ci va remplacer. Sans cela, sa réponse écrirait
    // dans l'état les classes d'un frais sous le nom d'un autre — invisible
    // tant que le niveau reste replié, mais l'état porterait un mensonge.
    _classesGeneration++;
    emit(
      state.copyWith(
        status: EnrollmentLoadStatus.loading,
        errorType: null,
        errorMessage: null,
      ),
    );

    final outcome = await _getPositions(
      academicYearId: query.academicYearId,
      feeCode: query.feeCode,
      schoolLevelGroupId: query.schoolLevelGroupId,
    );
    if (generation != _loadGeneration) return;

    _positions = outcome.getOrElse(() => const <LocalFeeLevelAggregate>[]);

    emit(
      outcome.fold(
        (failure) => state.copyWith(
          status: EnrollmentLoadStatus.failure,
          // Le résumé retombe à vide : garder à l'écran le classement d'une
          // lecture précédente, à côté d'un message d'échec, laisserait croire
          // que ces chiffres valent encore pour les critères affichés.
          summary: FeeControlDashboardSummary.empty,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: failure.message,
          lastQuery: query,
          unbilled: null,
          // Toute nouvelle lecture REPLIE : les classes affichées étaient
          // celles d'un autre frais, ou d'un autre périmètre. Les laisser
          // ouvertes sous des critères qui ont changé les ferait mentir.
          expandedLevelId: null,
          classesStatus: EnrollmentLoadStatus.initial,
          classes: const <FeeControlClassRow>[],
          classroomsMissing: false,
        ),
        (positions) => state.copyWith(
          status: EnrollmentLoadStatus.success,
          summary: FeeControlDashboardProjector.project(positions),
          errorType: null,
          errorMessage: null,
          lastQuery: query,
          unbilled: null,
          expandedLevelId: null,
          classesStatus: EnrollmentLoadStatus.initial,
          classes: const <FeeControlClassRow>[],
          classroomsMissing: false,
        ),
      ),
    );

    if (outcome.isRight()) {
      await _loadUnbilled(query, generation, emit);
    }
  }

  /// Compte les inscrits du périmètre **qu'aucune créance de ce frais ne
  /// concerne** — ceux que l'écran ne compte ni comme soldés, ni comme
  /// débiteurs, et qu'il tairait sans cela.
  ///
  /// **Best-effort, et volontairement à part de la lecture principale.** Cette
  /// information est complémentaire : si elle manque, le taux reste juste. La
  /// faire porter par le même `Either` aurait fait tomber tout l'écran en échec
  /// pour un compteur d'appoint — et le guichet aurait perdu le classement en
  /// même temps que la note.
  ///
  /// ⚠️ Compte des **élèves distincts**, jamais les couples (élève, niveau) du
  /// classement : un élève à cheval sur deux niveaux compte deux fois là-bas
  /// (D5), et le soustraire deux fois ici inventerait un non-facturé.
  Future<void> _loadUnbilled(
    FeeControlDashboardQuery query,
    int generation,
    Emitter<FeeControlDashboardState> emit,
  ) async {
    final outcome = await _searchEnrollments.currentYearEnrolled(
      academicYearId: query.academicYearId,
      schoolLevelGroupId: query.schoolLevelGroupId,
    );
    if (generation != _loadGeneration || emit.isDone) return;

    outcome.fold((_) {}, (enrolled) {
      final concerned = _positions.map((p) => p.studentId).toSet();
      // Deux ensembles d'ÉLÈVES, jamais deux listes de lignes. La recherche
      // rend des dossiers : un élève qui en porte deux sur la même année — une
      // pré-inscription reprise, un brouillon local à côté du dossier
      // descendu — y figure deux fois, et compter les lignes inventerait un
      // second non-facturé qui n'existe pas.
      final unbilled = enrolled
          .map((item) => item.studentId)
          .toSet()
          .difference(concerned)
          .length;
      emit(state.copyWith(unbilled: unbilled));
    });
  }

  // ── Dépliage d'un niveau en classes ─────────────────────────────────────────

  /// Ouvre un niveau, ou le referme s'il l'était déjà.
  ///
  /// **Aucune relecture du grand-livre** : les élèves du niveau sont déjà en
  /// mémoire ([_positions]), et seule leur affectation manque. Deux lectures du
  /// référentiel Classe suffisent — les classes pour leurs noms, les rosters
  /// composés (transferts locaux compris) pour leur composition.
  Future<void> _onGroupToggled(
    FeeControlDashboardGroupToggled event,
    Emitter<FeeControlDashboardState> emit,
  ) async {
    final levelId = event.schoolLevelId;
    // Sans niveau, il n'y a pas de classe où chercher : le groupe « niveau non
    // renseigné » ne se déplie pas.
    if (levelId == null) return;

    if (state.expandedLevelId == levelId) {
      _classesGeneration++; // une réponse en vol ne rouvrira pas ce qu'on ferme
      emit(
        state.copyWith(
          expandedLevelId: null,
          classesStatus: EnrollmentLoadStatus.initial,
          classes: const <FeeControlClassRow>[],
          classroomsMissing: false,
        ),
      );
      return;
    }

    final generation = ++_classesGeneration;
    emit(
      state.copyWith(
        expandedLevelId: levelId,
        classesStatus: EnrollmentLoadStatus.loading,
        classes: const <FeeControlClassRow>[],
        classroomsMissing: false,
      ),
    );

    final classroomsOutcome = await _getClassrooms(
      academicYearId: event.academicYearId,
      schoolLevelId: levelId,
    );
    if (generation != _classesGeneration) return;

    final classrooms = classroomsOutcome.getOrElse(
      () => const <OfflineClassroom>[],
    );
    if (classroomsOutcome.isLeft()) {
      emit(state.copyWith(classesStatus: EnrollmentLoadStatus.failure));
      return;
    }

    final rostersOutcome = await _getRosters(
      academicYearId: event.academicYearId,
      schoolLevelId: levelId,
    );
    if (generation != _classesGeneration) return;

    if (rostersOutcome.isLeft()) {
      emit(state.copyWith(classesStatus: EnrollmentLoadStatus.failure));
      return;
    }

    final rows = FeeControlDashboardClassProjector.project(
      positions: [
        for (final position in _positions)
          if (position.schoolLevelId == levelId) position,
      ],
      classrooms: classrooms,
      rosters: rostersOutcome.getOrElse(
        () => const <String, List<ClassroomMember>>{},
      ),
    );

    emit(
      state.copyWith(
        classesStatus: EnrollmentLoadStatus.success,
        classes: rows,
        // Aucune classe au référentiel : le rendu dira laquelle des deux causes
        // — droits ou synchronisation — puisqu'il est seul à connaître les
        // permissions de la session.
        classroomsMissing: classrooms.isEmpty,
      ),
    );
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Les échecs sont ici locaux (accès sqflite) : on les présente via le type
  /// d'erreur générique « serveur » des états partagés (jamais réseau/401/403).
  /// Même mapping que `FeeControlBloc` — un même incident ne doit pas se dire
  /// autrement d'un écran à l'autre du module.
  static EnrollmentErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => EnrollmentErrorType.network,
      StorageFailure() => EnrollmentErrorType.server,
      _ => EnrollmentErrorType.unknown,
    };
  }
}
