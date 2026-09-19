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

  /// La vente a-t-elle quelque chose à **réclamer** au serveur ?
  ///
  /// Deux manques distincts, et le second est le plus sournois :
  ///  - **aucune pièce** — le scellement au push est *best-effort*, et l'ACK
  ///    peut revenir sans document sur un 201 parfaitement en ligne ;
  ///  - **une pièce sans son numéro** — le delta des ventes porte l'identifiant
  ///    d'archive mais **jamais** le numéro (il ne l'invente pas). Le reçu est
  ///    alors ouvrable, et la ligne « Reçu » affiche pourtant une référence
  ///    provisoire — pour toujours, sur une vente parfaitement scellée.
  ///
  /// ⚠️ Réservé aux ventes que le serveur **connaît**. Sur une vente encore en
  /// attente de synchro, l'identifiant présenté est un uuid client qu'il ne
  /// trouverait pas : le bouton promettrait un 404.
  bool get canClaimReceipt =>
      sale.sale.syncStatus == 'SYNCED' &&
      (!hasSealedReceipt || (sale.sale.receiptNumber ?? '').trim().isEmpty);

  /// ⚠️ C'était `[sale.id, ticketPrintedAt]`, et c'est **le** piège de cet
  /// écran : `SaleDetailState` compare son `detail`, donc un cubit qui relit une
  /// vente dont seul un champ a changé émettait un état jugé ÉGAL au précédent —
  /// et un `Cubit` n'émet pas un état égal. L'écran restait sur ses valeurs
  /// périmées sans que rien ne le signale.
  @override
  List<Object?> get props => [sale, ticketPrintedAt];
}
