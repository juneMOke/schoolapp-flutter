import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';

/// Une vente **enregistrée localement** — l'encaissement a eu lieu.
///
/// C'est ce que rend l'écriture, et ce dont le ticket a besoin : à cet instant
/// le serveur ne sait encore rien, et le guichet doit pouvoir imprimer.
class RecordedSale extends Equatable {
  final BoutiqueSaleLocalModel sale;
  final List<BoutiqueSaleLineLocalModel> lines;

  const RecordedSale({required this.sale, required this.lines});

  String get id => sale.id;

  /// Somme des quantités — ce que le client compte en recevant ses articles.
  int get articleCount => lines.fold(0, (sum, line) => sum + line.quantity);

  @override
  List<Object?> get props => [sale.id, lines.length];
}
