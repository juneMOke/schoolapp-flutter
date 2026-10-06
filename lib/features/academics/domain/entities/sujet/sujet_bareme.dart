import 'package:equatable/equatable.dart';

/// Où en est le barème : la somme des points des questions face au maximum.
enum BaremeStatus {
  /// Aucun point attribué.
  empty,

  /// Il reste des points à répartir.
  under,

  /// La somme égale le maximum.
  complete,

  /// La somme dépasse le maximum.
  over,
}

/// Barème d'un sujet (spec S4). Jamais bloquant : un sujet en préparation
/// s'enregistre incomplet.
class SujetBareme extends Equatable {
  final double total;
  final double maxPoints;

  const SujetBareme({required this.total, required this.maxPoints});

  /// Tolérance d'arrondi sur des points décimaux.
  static const double _epsilon = 0.001;

  BaremeStatus get status {
    if (total <= _epsilon) return BaremeStatus.empty;
    if ((total - maxPoints).abs() <= _epsilon) return BaremeStatus.complete;
    return total < maxPoints ? BaremeStatus.under : BaremeStatus.over;
  }

  /// Écart absolu au maximum (points restants, ou dépassement).
  double get gap => (maxPoints - total).abs();

  /// Part du maximum couverte, plafonnée à 1.
  double get fraction =>
      maxPoints <= 0 ? 0 : (total / maxPoints).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [total, maxPoints];
}
