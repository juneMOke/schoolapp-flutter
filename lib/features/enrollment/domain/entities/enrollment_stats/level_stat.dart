import 'package:equatable/equatable.dart';

/// Un niveau et son effectif sur la fenêtre.
class LevelStat extends Equatable {
  /// Identifiant du niveau — sert le renvoi vers Première inscription.
  final String id;

  final String code;

  /// Libellé lisible (« 6e année »). Sans lui, la ligne n'afficherait que son
  /// code : c'est ce qui manquait au contrat précédent.
  final String label;

  /// Code du cycle porteur, qui donne sa couleur à la barre.
  final String cycle;

  final int value;

  const LevelStat({
    required this.id,
    required this.code,
    required this.label,
    required this.cycle,
    required this.value,
  });

  /// Ce qu'on écrit à gauche de la barre : le libellé, ou le code s'il manque.
  String get displayLabel => label.trim().isEmpty ? code : label;

  @override
  List<Object?> get props => [id, code, label, cycle, value];
}
