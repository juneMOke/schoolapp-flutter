part of 'recouvrement_dashboard_bloc.dart';

const _undefined = Object();

class RecouvrementDashboardState extends Equatable {
  // ── Natures de frais offertes à la sélection ───────────────────────────────

  final EnrollmentLoadStatus feeCodesStatus;

  /// Codes de nature, triés par effectif porté. **Jamais de libellé** : le rendu
  /// les nomme par le titre que l'école donne à la nature
  /// (`recouvrementFeeTitle`), jamais par le libellé d'un tarif — l'écran est
  /// école-wide, et un même code en porte de différents d'un niveau à l'autre.
  final List<String> feeCodes;

  // ── Position de la population sur la sélection ─────────────────────────────

  final EnrollmentLoadStatus status;

  /// Les quatre chiffres de tête, projetés des lignes du registre.
  final RecouvrementKeyFigures figures;

  /// Le taux de recouvrement **par poste, groupé par devise**.
  ///
  /// Projeté ici plutôt que dérivé par l'écran : c'est une réduction stable des
  /// mêmes lignes, au même titre que [figures], et la faire calculer par la vue
  /// l'obligerait à lire les lignes hors état — donc à connaître le bloc
  /// autrement que par son état.
  final List<RecouvrementCurrencyGroup> rates;

  /// Les niveaux, **classés du plus en retard au plus en règle**.
  ///
  /// Le classement nourrit la lecture « écart » de fin de page, qui nomme le
  /// niveau en tête et celui qui ferme la marche. « Où en est chaque niveau »
  /// reprend les MÊMES lignes et les range dans l'ordre de l'école, cycle par
  /// cycle, sans rien recompter : les deux ne peuvent pas se contredire.
  final RecouvrementRankingSummary ranking;

  /// Inscrits du périmètre qui **ne portent aucun frais de la sélection**.
  ///
  /// `null` quand on ne sait pas : lecture pas encore faite, ou échouée. C'est
  /// délibérément distinct de `0` — « personne n'est hors facturation » et « on
  /// n'a pas pu vérifier » n'autorisent pas le même silence.
  ///
  /// **Jamais dans le taux.** Un élève sans créance de ces frais n'est pas un
  /// mauvais payeur : il n'est pas facturé.
  final int? unbilled;

  final EnrollmentErrorType? errorType;
  final String? errorMessage;

  /// Ce dont [figures] est le résultat. `null` tant qu'aucune lecture n'a
  /// abouti — ce qui distingue « rien demandé » de « demandé, rien trouvé ».
  final RecouvrementQuery? lastQuery;

  /// Numéro de la lecture en vigueur, incrémenté à chaque tentative.
  ///
  /// C'est le **signal** que les lignes hors état ont changé : la simulation, le
  /// classement et le taux par frais les relisent quand il bouge, sans que
  /// l'état ait à porter des milliers d'objets dans son `Equatable`. Il change
  /// aussi sur un échec, car les lignes y retombent à vide.
  final int snapshotId;

  const RecouvrementDashboardState({
    this.feeCodesStatus = EnrollmentLoadStatus.initial,
    this.feeCodes = const <String>[],
    this.status = EnrollmentLoadStatus.initial,
    this.figures = RecouvrementKeyFigures.empty,
    this.rates = const <RecouvrementCurrencyGroup>[],
    this.ranking = RecouvrementRankingSummary.empty,
    this.unbilled,
    this.errorType,
    this.errorMessage,
    this.lastQuery,
    this.snapshotId = 0,
  });

  const RecouvrementDashboardState.initial() : this();

  /// Vrai quand une lecture a abouti sans trouver un seul élève concerné —
  /// l'état vide des résultats, à ne pas confondre avec l'écran encore vierge.
  ///
  /// ⚠️ Ce n'est **pas** le vide structurel de la spec (§12). Un périmètre qui
  /// ne renvoie personne reste un état `ready` : c'est un filtrage, et on ne
  /// remplace la page que si aucun attendu n'existe — sinon l'utilisateur
  /// perdrait de vue la sélection qu'il vient de faire.
  bool get hasEmptyResult =>
      status == EnrollmentLoadStatus.success && figures.isEmpty;

  RecouvrementDashboardState copyWith({
    EnrollmentLoadStatus? feeCodesStatus,
    List<String>? feeCodes,
    EnrollmentLoadStatus? status,
    RecouvrementKeyFigures? figures,
    List<RecouvrementCurrencyGroup>? rates,
    RecouvrementRankingSummary? ranking,
    Object? unbilled = _undefined,
    Object? errorType = _undefined,
    Object? errorMessage = _undefined,
    Object? lastQuery = _undefined,
    int? snapshotId,
  }) => RecouvrementDashboardState(
    feeCodesStatus: feeCodesStatus ?? this.feeCodesStatus,
    feeCodes: feeCodes ?? this.feeCodes,
    status: status ?? this.status,
    figures: figures ?? this.figures,
    rates: rates ?? this.rates,
    ranking: ranking ?? this.ranking,
    unbilled: identical(unbilled, _undefined)
        ? this.unbilled
        : unbilled as int?,
    errorType: identical(errorType, _undefined)
        ? this.errorType
        : errorType as EnrollmentErrorType?,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
    lastQuery: identical(lastQuery, _undefined)
        ? this.lastQuery
        : lastQuery as RecouvrementQuery?,
    snapshotId: snapshotId ?? this.snapshotId,
  );

  @override
  List<Object?> get props => [
    feeCodesStatus,
    feeCodes,
    status,
    figures,
    rates,
    ranking,
    unbilled,
    errorType,
    errorMessage,
    lastQuery,
    snapshotId,
  ];
}
