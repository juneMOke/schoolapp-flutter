import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';

/// Une ligne d'une vente **encaissée sur ce poste et pas encore acceptée** par
/// le serveur — en file, ou en échec.
///
/// Le serveur ne la connaît pas : ses statistiques ne la comptent pas. Le
/// tableau de bord l'ajoute donc lui-même, et le dit.
class ProvisionalSaleLine extends Equatable {
  final String saleId;

  /// L'heure **métier** de la vente, en UTC.
  final DateTime soldAt;

  final String currency;

  /// En centimes.
  final int lineTotal;
  final int quantity;

  /// Lue sur le catalogue local ; `null` si l'article n'y est plus.
  final ArticleFamily? family;

  const ProvisionalSaleLine({
    required this.saleId,
    required this.soldAt,
    required this.currency,
    required this.lineTotal,
    required this.quantity,
    this.family,
  });

  @override
  List<Object?> get props => [
    saleId,
    soldAt,
    currency,
    lineTotal,
    quantity,
    family,
  ];
}
