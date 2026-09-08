import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipt.dart';

/// Une page de la table des reçus — **et ce que la fenêtre entière dit d'elle**.
///
/// La table est paginée **côté serveur**, et scopée à **une caisse** : la devise
/// est un paramètre d'appel obligatoire, pas un filtre appliqué après coup.
/// Filtrer une page reçue ramènerait huit lignes à trois, avec un compteur faux
/// et une pagination qui saute.
class TillReceiptsPage extends Equatable {
  final List<TillReceipt> content;

  /// Rang de la page, **à partir de zéro** — comme le serveur la numérote. La
  /// barre de pagination du socle compte à partir de 1 ; la conversion se fait
  /// au montage, jamais dans l'état.
  final int page;

  final int size;

  /// Ce que la **fenêtre** contient dans cette caisse, toutes pages confondues.
  final int totalElements;

  final int totalPages;

  /// Combien de lignes de la **fenêtre** n'ont aucune pièce scellée.
  ///
  /// ⚠️ **Portée fenêtre, jamais page** — c'est tout l'intérêt du champ. Le
  /// sous-titre mêle trois chiffres (« 17 reçus · 4 120 $ · 2 sans pièce
  /// scellée ») qui doivent tous porter sur la même chose ; compté sur les huit
  /// lignes reçues, le dernier changerait à chaque tour de pagination sous un
  /// total immobile.
  ///
  /// ⚠️ **Ne s'infère pas depuis la colonne, et réciproquement.** Le serveur
  /// compte les versements **sans pièce émise** — les saisies de rattrapage, ce
  /// que la spec vise. Une pièce émise dont le numéro ne se résout plus affiche
  /// la même marque neutre dans la colonne **sans entrer dans ce compte**. Une
  /// colonne peut donc porter plus de tirets que ce sous-titre n'annonce de
  /// rattrapages, et c'est voulu : dériver l'un de l'autre ferait mentir celui
  /// qu'on dérive.
  final int withoutReceiptNumber;

  const TillReceiptsPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.withoutReceiptNumber,
  });

  static const TillReceiptsPage empty = TillReceiptsPage(
    content: [],
    page: 0,
    size: 0,
    totalElements: 0,
    totalPages: 0,
    withoutReceiptNumber: 0,
  );

  /// La fenêtre n'a produit aucune ligne dans cette caisse.
  bool get isEmpty => totalElements == 0;

  /// La pagination a un sens : il y a plus d'une page à parcourir.
  bool get hasMultiplePages => totalPages > 1;

  /// Des versements de la fenêtre n'ont jamais eu de pièce scellée, et le
  /// sous-titre doit le dire — sinon une colonne presque vide se lit comme une
  /// table cassée plutôt que comme un fait.
  bool get hasUnsealedReceipts => withoutReceiptNumber > 0;

  @override
  List<Object?> get props => [
    content,
    page,
    size,
    totalElements,
    totalPages,
    withoutReceiptNumber,
  ];
}
