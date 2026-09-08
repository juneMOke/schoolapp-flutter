part of 'finance_till_receipts_bloc.dart';

const Object _undefined = Object();

enum FinanceTillReceiptsStatus { initial, loading, success, empty, error }

class FinanceTillReceiptsState extends Equatable {
  final FinanceTillReceiptsStatus status;

  /// La caisse décrite. Nulle tant qu'aucune n'a été demandée.
  final String? currency;

  /// La fenêtre servie — retenue pour que tourner une page rejoue **la même**.
  final TillPeriod period;

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

  /// L'échec lui-même, pour que la vue distingue un **droit manquant** d'une
  /// panne : un 403 ici est normal pour un porteur du seul pilotage, et il ne
  /// doit ni ressembler à une erreur réseau ni emporter les cartes.
  final Failure? failure;

  const FinanceTillReceiptsState({
    this.status = FinanceTillReceiptsStatus.initial,
    this.currency,
    this.period = TillPeriod.day,
    this.receipts = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.withoutReceiptNumber = 0,
    this.failure,
  });

  /// La pagination a un sens : plus d'une page à parcourir.
  bool get hasMultiplePages => totalPages > 1;

  /// Des versements de la fenêtre n'ont jamais eu de pièce scellée, et le
  /// sous-titre doit le dire.
  bool get hasUnsealedReceipts => withoutReceiptNumber > 0;

  FinanceTillReceiptsState copyWith({
    FinanceTillReceiptsStatus? status,
    Object? currency = _undefined,
    TillPeriod? period,
    List<TillReceipt>? receipts,
    int? page,
    int? totalElements,
    int? totalPages,
    int? withoutReceiptNumber,
    Object? failure = _undefined,
  }) => FinanceTillReceiptsState(
    status: status ?? this.status,
    currency: identical(currency, _undefined)
        ? this.currency
        : currency as String?,
    period: period ?? this.period,
    receipts: receipts ?? this.receipts,
    page: page ?? this.page,
    totalElements: totalElements ?? this.totalElements,
    totalPages: totalPages ?? this.totalPages,
    withoutReceiptNumber: withoutReceiptNumber ?? this.withoutReceiptNumber,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
  );

  @override
  List<Object?> get props => [
    status,
    currency,
    period,
    receipts,
    page,
    totalElements,
    totalPages,
    withoutReceiptNumber,
    failure,
  ];
}
