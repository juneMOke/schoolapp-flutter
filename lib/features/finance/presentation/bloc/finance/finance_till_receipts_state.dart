part of 'finance_till_receipts_bloc.dart';

const Object _undefined = Object();

enum FinanceTillReceiptsStatus { initial, loading, success, empty, error }

class FinanceTillReceiptsState extends Equatable {
  final FinanceTillReceiptsStatus status;

  /// La fenêtre servie — retenue pour que tourner une page rejoue **la même**.
  final TillWindow window;

  final List<TillReceipt> receipts;

  /// Page courante, **0-based** — celle du serveur. La barre de pagination du
  /// socle compte à partir de 1 ; la conversion se fait au montage, jamais ici.
  final int page;

  final int totalElements;
  final int totalPages;

  /// Combien de lignes **de la fenêtre** n'ont aucune pièce scellée.
  ///
  /// ⚠️ Portée fenêtre, comme [totalElements] — jamais un compte des lignes
  /// affichées. C'est ce qui permet au sous-titre d'aligner trois chiffres qui
  /// parlent de la même chose.
  final int withoutReceiptNumber;

  /// L'année de la fenêtre servie, lue sur **l'enveloppe** de la page.
  ///
  /// Second paramètre de route de la fiche de facturation. `null` tant que le
  /// contrat ne la sert pas — et alors aucun œil ne s'allume : pousser une route
  /// à laquelle il manque un paramètre est refusé par le redirect de garde.
  final String? academicYearId;

  /// L'échec lui-même, pour que la vue distingue un **droit manquant** d'une
  /// panne : un 403 ici est normal pour un porteur du seul pilotage, et il ne
  /// doit ni ressembler à une erreur réseau ni emporter les cartes.
  final Failure? failure;

  const FinanceTillReceiptsState({
    this.status = FinanceTillReceiptsStatus.initial,
    this.window = const TillWindow.day(),
    this.receipts = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.withoutReceiptNumber = 0,
    this.academicYearId,
    this.failure,
  });

  /// La pagination a un sens : plus d'une page à parcourir.
  bool get hasMultiplePages => totalPages > 1;

  /// Des versements de la fenêtre n'ont jamais eu de pièce scellée, et le
  /// sous-titre doit le dire.
  bool get hasUnsealedReceipts => withoutReceiptNumber > 0;

  FinanceTillReceiptsState copyWith({
    FinanceTillReceiptsStatus? status,
    TillWindow? window,
    List<TillReceipt>? receipts,
    int? page,
    int? totalElements,
    int? totalPages,
    int? withoutReceiptNumber,
    Object? academicYearId = _undefined,
    Object? failure = _undefined,
  }) => FinanceTillReceiptsState(
    status: status ?? this.status,
    window: window ?? this.window,
    receipts: receipts ?? this.receipts,
    page: page ?? this.page,
    totalElements: totalElements ?? this.totalElements,
    totalPages: totalPages ?? this.totalPages,
    withoutReceiptNumber: withoutReceiptNumber ?? this.withoutReceiptNumber,
    // Sentinelle et non `??` : `null` est une valeur SIGNIFIANTE ici — l'échec
    // efface l'année, et un `??` ne saurait pas distinguer « efface-la » de
    // « n'y touche pas ».
    academicYearId: identical(academicYearId, _undefined)
        ? this.academicYearId
        : academicYearId as String?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
  );

  @override
  List<Object?> get props => [
    status,
    window,
    receipts,
    page,
    totalElements,
    totalPages,
    withoutReceiptNumber,
    academicYearId,
    failure,
  ];
}
