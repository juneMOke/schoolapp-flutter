import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_codes_for_year_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_class_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_fee_rates.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_ranking_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_key_figures.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/recouvrement_contracts.dart';

// Un seul import suffit aux widgets du tableau de bord.
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
export 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
export 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_key_figures.dart';
export 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_fee_rates.dart'
    show RecouvrementCurrencyGroup, RecouvrementFeeRate;
export 'package:school_app_flutter/features/recouvrement/presentation/contracts/recouvrement_contracts.dart';
export 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_class_projector.dart'
    show RecouvrementClassRow;
export 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_ranking_projector.dart'
    show RecouvrementRankingSummary, RecouvrementGroupRow;

part 'recouvrement_dashboard_event.dart';
part 'recouvrement_dashboard_state.dart';

/// BLoC du tableau de bord du **Recouvrement** : où en est la dette sur une
/// sélection de frais, et qui décroche.
///
/// Lecture **100 % locale**, en deux temps indépendants : les natures de frais
/// facturées sur l'année, puis la position de toute la population sur celles
/// qu'on retient. Aucune écriture — cet écran regarde, il n'encaisse pas.
///
/// ## Une seule lecture porte tout l'écran
///
/// Les quatre chiffres clés, le taux par frais, le classement et la simulation
/// dérivent tous des **mêmes** lignes, en mémoire. C'est ce que la spec exige :
/// cocher un frais ne doit pas rejouer un chargement, et le curseur de seuil
/// doit se sentir immédiat. C'est aussi ce qui a fait retirer `/ledger` côté
/// serveur — le registre est déjà là, et lui seul voit les encaissements non
/// encore remontés.
///
/// **Le cycle n'est pas chargé ici** : la liste des cycles vient du contexte
/// académique (`AcademicYearContextBloc`), que la page a déjà sous la main.
class RecouvrementDashboardBloc
    extends Bloc<RecouvrementDashboardEvent, RecouvrementDashboardState> {
  final GetFeeCodesForYearUseCase _getFeeCodes;
  final GetRecoveryPositionsUseCase _getPositions;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetComposedRostersUseCase _getRosters;
  final SearchLocalEnrollmentsUseCase _searchEnrollments;

  /// Lignes de la dernière lecture, gardées **hors de l'état**.
  ///
  /// Les reconserver dans l'état alourdirait chaque comparaison d'`Equatable`
  /// de plusieurs milliers d'objets, à chaque `buildWhen`, pour une donnée que
  /// l'écran ne rend jamais telle quelle : il n'en montre que des projections.
  /// Les consommateurs qui en ont besoin — la simulation — les lisent par
  /// [lines], et savent qu'elles ont changé par [RecouvrementDashboardState.
  /// snapshotId].
  List<LocalRecoveryLine> _lines = const <LocalRecoveryLine>[];

  /// Le registre de la dernière lecture réussie. Vide tant qu'aucune n'a abouti.
  List<LocalRecoveryLine> get lines => List.unmodifiable(_lines);

  // Générations de chargement : le transformer par défaut du bloc étant
  // `concurrent`, deux lectures peuvent voler en parallèle — cocher deux frais
  // coup sur coup suffit. Chaque lecture capture le numéro courant ; seule la
  // PLUS RÉCENTE écrit et émet. Sans cela, une lecture périmée résolue en
  // dernier repeindrait l'écran sous le nom d'une autre sélection.
  int _feeCodesGeneration = 0;
  int _loadGeneration = 0;
  int _classesGeneration = 0;
  int _snapshotId = 0;

  RecouvrementDashboardBloc({
    required GetFeeCodesForYearUseCase getFeeCodes,
    required GetRecoveryPositionsUseCase getPositions,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetComposedRostersUseCase getRosters,
    required SearchLocalEnrollmentsUseCase searchEnrollments,
  }) : _getFeeCodes = getFeeCodes,
       _getPositions = getPositions,
       _getClassrooms = getClassrooms,
       _getRosters = getRosters,
       _searchEnrollments = searchEnrollments,
       super(const RecouvrementDashboardState.initial()) {
    on<RecouvrementFeeCodesRequested>(_onFeeCodesRequested);
    on<RecouvrementRequested>(_onRequested);
    on<RecouvrementRefreshRequested>(_onRefreshRequested);
    on<RecouvrementGroupToggled>(_onGroupToggled);
  }

  // ── Natures de frais ────────────────────────────────────────────────────────

  Future<void> _onFeeCodesRequested(
    RecouvrementFeeCodesRequested event,
    Emitter<RecouvrementDashboardState> emit,
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
    RecouvrementRequested event,
    Emitter<RecouvrementDashboardState> emit,
  ) => _load(
    RecouvrementQuery.of(
      academicYearId: event.academicYearId,
      feeCodes: event.feeCodes,
      schoolLevelGroupId: _nullIfEmpty(event.schoolLevelGroupId),
    ),
    emit,
  );

  /// Rejoue la dernière lecture. Sans `lastQuery`, ne fait **rien** : une
  /// reprise qui interrogerait autre chose que ce qui a échoué mentirait sur ce
  /// qu'elle répare.
  Future<void> _onRefreshRequested(
    RecouvrementRefreshRequested event,
    Emitter<RecouvrementDashboardState> emit,
  ) async {
    final query = state.lastQuery;
    if (query == null) return;
    await _load(query, emit);
  }

  Future<void> _load(
    RecouvrementQuery query,
    Emitter<RecouvrementDashboardState> emit,
  ) async {
    // Une sélection vide ne s'interroge pas : elle ne rendrait rien, et l'écran
    // l'interdit déjà. On le dit ici aussi — un bloc ne se repose pas sur la
    // discipline de son appelant pour rester cohérent.
    if (query.feeCodes.isEmpty) return;

    final generation = ++_loadGeneration;
    // Un dépliage EN VOL est annulé avec la lecture qu'il détaillait : il lit
    // `_lines`, que celle-ci va remplacer. Sans cela, sa réponse écrirait dans
    // l'état les classes d'une sélection sous le nom d'une autre.
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
      feeCodes: query.feeCodes,
      schoolLevelGroupId: query.schoolLevelGroupId,
    );
    if (generation != _loadGeneration) return;

    _lines = outcome.getOrElse(() => const <LocalRecoveryLine>[]);

    emit(
      outcome.fold(
        (failure) => state.copyWith(
          status: EnrollmentLoadStatus.failure,
          // Les chiffres retombent à vide : garder à l'écran ceux d'une lecture
          // précédente, à côté d'un message d'échec, laisserait croire qu'ils
          // valent encore pour la sélection affichée.
          figures: RecouvrementKeyFigures.empty,
          rates: const <RecouvrementCurrencyGroup>[],
          ranking: RecouvrementRankingSummary.empty,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: failure.message,
          lastQuery: query,
          unbilled: null,
          snapshotId: ++_snapshotId,
          // Toute nouvelle lecture REPLIE : les classes affichées étaient
          // celles d'une autre sélection ou d'un autre périmètre. Les laisser
          // ouvertes sous des critères qui ont changé les ferait mentir.
          expandedLevelId: null,
          classesStatus: EnrollmentLoadStatus.initial,
          classes: const <RecouvrementClassRow>[],
          classroomsMissing: false,
        ),
        (lines) => state.copyWith(
          status: EnrollmentLoadStatus.success,
          figures: RecouvrementKeyFiguresProjector.project(lines),
          rates: RecouvrementFeeRatesProjector.project(lines),
          ranking: RecouvrementRankingProjector.project(lines),
          errorType: null,
          errorMessage: null,
          lastQuery: query,
          unbilled: null,
          snapshotId: ++_snapshotId,
          expandedLevelId: null,
          classesStatus: EnrollmentLoadStatus.initial,
          classes: const <RecouvrementClassRow>[],
          classroomsMissing: false,
        ),
      ),
    );

    if (outcome.isRight()) {
      await _loadUnbilled(query, generation, emit);
    }
  }

  /// Compte les inscrits du périmètre **qu'aucune créance de la sélection ne
  /// concerne** — ceux que l'écran ne compte ni comme soldés, ni comme
  /// débiteurs, et qu'il tairait sans cela.
  ///
  /// **Best-effort, et volontairement à part de la lecture principale.** Si
  /// elle manque, le taux reste juste. La faire porter par le même `Either`
  /// aurait fait tomber tout l'écran pour un compteur d'appoint.
  ///
  /// ⚠️ Compte des **élèves distincts**, jamais les couples (élève, niveau) du
  /// classement : un élève à cheval sur deux niveaux compte deux fois là-bas,
  /// et le soustraire deux fois ici inventerait un non-facturé.
  Future<void> _loadUnbilled(
    RecouvrementQuery query,
    int generation,
    Emitter<RecouvrementDashboardState> emit,
  ) async {
    final outcome = await _searchEnrollments.currentYearEnrolled(
      academicYearId: query.academicYearId,
      schoolLevelGroupId: query.schoolLevelGroupId,
    );
    if (generation != _loadGeneration || emit.isDone) return;

    outcome.fold((_) {}, (enrolled) {
      final concerned = _lines.map((line) => line.studentId).toSet();
      // Deux ensembles d'ÉLÈVES, jamais deux listes de lignes : un élève qui
      // porte deux dossiers sur la même année y figurerait deux fois, et
      // compter les lignes inventerait un non-facturé qui n'existe pas.
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
  /// mémoire, et seule leur affectation manque. Deux lectures du référentiel
  /// Classe suffisent — les classes pour leurs noms, les rosters composés
  /// (transferts locaux compris) pour leur composition.
  Future<void> _onGroupToggled(
    RecouvrementGroupToggled event,
    Emitter<RecouvrementDashboardState> emit,
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
          classes: const <RecouvrementClassRow>[],
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
        classes: const <RecouvrementClassRow>[],
        classroomsMissing: false,
      ),
    );

    final classroomsOutcome = await _getClassrooms(
      academicYearId: event.academicYearId,
      schoolLevelId: levelId,
    );
    if (generation != _classesGeneration) return;
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

    final classrooms = classroomsOutcome.getOrElse(
      () => const <OfflineClassroom>[],
    );

    emit(
      state.copyWith(
        classesStatus: EnrollmentLoadStatus.success,
        classes: RecouvrementClassProjector.project(
          positions: [
            for (final line in _lines)
              if (line.schoolLevelId == levelId) line,
          ],
          classrooms: classrooms,
          rosters: rostersOutcome.getOrElse(
            () => const <String, List<ClassroomMember>>{},
          ),
        ),
        // Aucune classe au référentiel : le rendu dira laquelle des deux causes
        // — droits ou synchronisation — puisqu'il est seul à connaître les
        // permissions de la session.
        classroomsMissing: classrooms.isEmpty,
      ),
    );
  }

  /// Une chaîne vide — ou blanche — vaut « pas de cycle » : les
  /// `DropdownButton` rendent leur sentinelle en `String`, et la laisser passer
  /// produirait une clause SQL qui ne filtre rien mais que personne n'a
  /// demandée. Le `trim` n'est pas décoratif : un identifiant fait d'espaces
  /// est aussi vide qu'une chaîne nue, et il descendrait jusqu'au SQL.
  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static EnrollmentErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => EnrollmentErrorType.network,
      StorageFailure() => EnrollmentErrorType.server,
      _ => EnrollmentErrorType.unknown,
    };
  }
}
