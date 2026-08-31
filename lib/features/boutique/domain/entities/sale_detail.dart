import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';

/// Une vente ouverte depuis l'historique : son contenu, et ce qu'on peut encore
/// en faire.
///
/// [sale] porte l'en-tête ET les lignes — c'est exactement la forme que réclame
/// la composition du ticket, et en fabriquer une seconde ferait diverger ce que
/// l'écran montre de ce que le papier imprime.
class SaleDetail extends Equatable {
  final RecordedSale sale;

  /// Quand le ticket est sorti de l'imprimante, `null` s'il ne l'a jamais été.
  ///
  /// **N'interdit jamais de réimprimer** : un papier se déchire, une imprimante
  /// se bloque à mi-course, et un client repart parfois sans son ticket. La
  /// mention informe, elle ne garde pas la porte.
  final DateTime? ticketPrintedAt;

  const SaleDetail({required this.sale, this.ticketPrintedAt});

  /// Le reçu scellé existe-t-il côté serveur ?
  ///
  /// C'est **l'identifiant d'archive** qui décide, pas le numéro : le numéro
  /// s'imprime, l'identifiant seul permet de re-télécharger la pièce. Le
  /// contrat autorise l'un sans l'autre.
  bool get hasSealedReceipt =>
      (sale.sale.receiptDocumentId ?? '').trim().isNotEmpty;

  bool get ticketWasPrinted => ticketPrintedAt != null;

  @override
  List<Object?> get props => [sale.id, ticketPrintedAt];
}
