import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/level_stat.dart';

/// Un cycle, son effectif et ses niveaux.
class CycleStat extends Equatable {
  final String code;

  /// Libellé lisible (« Primaire »). Sans lui la ligne « Par cycle »
  /// n'afficherait que `PRIMARY`.
  final String label;

  final int total;
  final List<LevelStat> levels;

  const CycleStat({
    required this.code,
    required this.label,
    required this.total,
    required this.levels,
  });

  String get displayLabel => label.trim().isEmpty ? code : label;

  @override
  List<Object?> get props => [code, label, total, levels];
}
