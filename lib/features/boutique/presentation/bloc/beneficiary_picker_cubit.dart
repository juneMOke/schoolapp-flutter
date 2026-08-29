import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_list_item.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';

/// Un élève proposable comme bénéficiaire d'une ligne.
class BeneficiaryCandidate extends Equatable {
  final String studentId;
  final String fullName;
  final String? schoolLevelId;
  final String? schoolLevelName;

  /// Vrai si l'inscription de l'élève est **synchronisée**.
  ///
  /// C'est cela — et non l'existence de l'élève — qui décide si le serveur
  /// saura dériver son niveau. Une inscription encore locale porte un uuid que
  /// le serveur n'a pas honoré : la vente passerait quand même (il ne refuse
  /// plus une ligne irrésoluble), mais avec une anomalie consignée et un reçu au
  /// bénéficiaire **anonyme**.
  final bool enrollmentSynced;

  const BeneficiaryCandidate({
    required this.studentId,
    required this.fullName,
    this.schoolLevelId,
    this.schoolLevelName,
    required this.enrollmentSynced,
  });

  /// Sélectionnable seulement si son niveau est connu **et** son inscription
  /// synchronisée. Le repli est nommé à l'écran : vendre au niveau, sans
  /// bénéficiaire, ce qui donne exactement le même prix.
  bool get isSelectable => enrollmentSynced && schoolLevelId != null;

  @override
  List<Object?> get props => [
    studentId,
    fullName,
    schoolLevelId,
    schoolLevelName,
    enrollmentSynced,
  ];
}

enum BeneficiaryPickerStatus { idle, loading, ready, failure }

class BeneficiaryPickerState extends Equatable {
  final BeneficiaryPickerStatus status;

  /// **Identité par défaut**, à rebours du socle de recherche — et c'est un cas
  /// d'usage différent, pas un écart de style. En Facturation on traite une
  /// classe entière ; à la caisse on sert **une** personne, souvent présente,
  /// dont on connaît le nom.
  final SearchMode mode;

  final String query;
  final String? schoolLevelId;
  final List<BeneficiaryCandidate> results;

  const BeneficiaryPickerState({
    this.status = BeneficiaryPickerStatus.idle,
    this.mode = SearchMode.identity,
    this.query = '',
    this.schoolLevelId,
    this.results = const [],
  });

  /// Seuil de la recherche libre. En dessous, on n'affiche **pas** l'effectif
  /// entier : une liste de six cents noms n'aide personne, et l'invite nomme
  /// l'autre mode.
  static const int minQueryLength = 2;

  /// Nombre maximal de résultats montrés — au-delà, c'est le nom qu'il faut
  /// préciser, pas la liste qu'il faut allonger.
  static const int maxResults = 8;

  bool get queryTooShort =>
      mode == SearchMode.identity && query.trim().length < minQueryLength;

  BeneficiaryPickerState copyWith({
    BeneficiaryPickerStatus? status,
    SearchMode? mode,
    String? query,
    String? schoolLevelId,
    bool clearLevel = false,
    List<BeneficiaryCandidate>? results,
  }) => BeneficiaryPickerState(
    status: status ?? this.status,
    mode: mode ?? this.mode,
    query: query ?? this.query,
    schoolLevelId: clearLevel ? null : (schoolLevelId ?? this.schoolLevelId),
    results: results ?? this.results,
  );

  @override
  List<Object?> get props => [status, mode, query, schoolLevelId, results];
}

/// La modale « Désigner un élève ».
///
/// **Deux voies, exclusives** (règle non négociable #12) : la recherche libre
/// quand on connaît le nom, le repli par niveau quand on ne l'a pas ou qu'on le
/// cherche mal. Jamais deux blocs concurrents reliés par un « OU ».
///
/// Le second mode est **par niveau** et non par classe, à rebours de la lettre
/// de la spec : c'est le niveau qui résout le prix, il est porté par chaque
/// ligne d'inscription, et passer par la classe demanderait ensuite de l'en
/// dériver — une lecture de plus pour la même réponse.
class BeneficiaryPickerCubit extends Cubit<BeneficiaryPickerState> {
  final SearchLocalEnrollmentsUseCase _search;
  final String academicYearId;

  BeneficiaryPickerCubit({
    required SearchLocalEnrollmentsUseCase search,
    required this.academicYearId,
  }) : _search = search,
       super(const BeneficiaryPickerState());

  void switchMode(SearchMode mode) {
    if (mode == state.mode) return;
    // La saisie de l'autre mode est CONSERVÉE : y revenir ne coûte pas de tout
    // retaper. Seuls les résultats tombent, parce qu'ils appartenaient au mode
    // qu'on quitte.
    emit(
      state.copyWith(
        mode: mode,
        results: const [],
        status: BeneficiaryPickerStatus.idle,
      ),
    );
  }

  Future<void> queryChanged(String query) async {
    emit(state.copyWith(query: query));
    if (state.queryTooShort) {
      emit(
        state.copyWith(results: const [], status: BeneficiaryPickerStatus.idle),
      );
      return;
    }
    await _load();
  }

  Future<void> levelChanged(String? schoolLevelId) async {
    emit(
      schoolLevelId == null
          ? state.copyWith(clearLevel: true, results: const [])
          : state.copyWith(schoolLevelId: schoolLevelId),
    );
    if (schoolLevelId == null) return;
    await _load();
  }

  Future<void> _load() async {
    emit(state.copyWith(status: BeneficiaryPickerStatus.loading));
    final result = await _search.currentYearEnrolled(
      academicYearId: academicYearId,
      // Le niveau ne borne la requête QUE dans son mode : l'emporter dans la
      // recherche par nom masquerait l'élève d'un autre niveau, qui est
      // justement celui qu'on ne retrouve pas.
      schoolLevelId: state.mode == SearchMode.level
          ? state.schoolLevelId
          : null,
    );

    result.fold(
      (_) => emit(state.copyWith(status: BeneficiaryPickerStatus.failure)),
      (items) => emit(
        state.copyWith(
          status: BeneficiaryPickerStatus.ready,
          results: _refine(items),
        ),
      ),
    );
  }

  /// Raffinage du nom **en Dart**.
  ///
  /// Le SQL ne filtre jamais sur un nom dans ce dépôt : `LOWER()` de SQLite ne
  /// plie pas les accents, et « Mwepu » ne retrouverait pas « Mwépu ».
  List<BeneficiaryCandidate> _refine(List<LocalEnrollmentListItem> items) {
    final matching = <BeneficiaryCandidate>[];

    for (final item in items) {
      final fullName = [
        item.lastName.trim(),
        item.surname?.trim() ?? '',
        item.firstName.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

      // `contains` replie le terme vide sur « tout passe » : c'est exactement
      // ce qu'il faut en mode niveau, où la liste de la classe s'affiche
      // entière et sans seuil.
      if (!SearchNormalizationHelper.contains(fullName, state.query)) continue;

      matching.add(
        BeneficiaryCandidate(
          studentId: item.studentId,
          fullName: fullName,
          schoolLevelId: item.schoolLevelId,
          schoolLevelName: item.schoolLevelName,
          enrollmentSynced: item.syncState == SyncState.synced,
        ),
      );
      if (matching.length >= BeneficiaryPickerState.maxResults) break;
    }
    return matching;
  }
}
