import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_bucket.dart';

class EvolutionBucketModel {
  final String key;
  final String shortLabel;
  final String longLabel;
  final int value;
  final bool isCurrent;

  const EvolutionBucketModel({
    required this.key,
    required this.shortLabel,
    required this.longLabel,
    required this.value,
    required this.isCurrent,
  });

  factory EvolutionBucketModel.fromJson(Map<String, dynamic> json) {
    return EvolutionBucketModel(
      key: json['key'] as String,
      // Repli sur la chaîne VIDE, jamais sur `key`.
      //
      // Un libellé absent laisse une graduation vide — visible, et corrigeable.
      // Se rabattre sur la clé ressusciterait le défaut que ces deux champs
      // suppriment : depuis que l'axe replie ce qui déborde, `key` vaut parfois
      // `out-of-axis-before`, et l'axe afficherait « fore ».
      shortLabel: json['shortLabel'] as String? ?? '',
      longLabel: json['longLabel'] as String? ?? '',
      value: (json['value'] as num).toInt(),
      isCurrent: json['isCurrent'] as bool,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'shortLabel': shortLabel,
    'longLabel': longLabel,
    'value': value,
    'isCurrent': isCurrent,
  };

  EvolutionBucket toEntity() => EvolutionBucket(
    key: key,
    shortLabel: shortLabel,
    longLabel: longLabel,
    value: value,
    isCurrent: isCurrent,
  );
}
