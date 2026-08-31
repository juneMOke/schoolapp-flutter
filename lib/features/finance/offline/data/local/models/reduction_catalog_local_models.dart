/// Modèles des tables du barème de réductions (ADR-021 V1).
///
/// Les deux tables sont un **référentiel scopé par école, pas par année** : le
/// barème descend à la racine du bundle, à côté de `school`. `schoolId` n'y est
/// donc pas décoratif — c'est la clé de purge, et la seule chose qui empêche le
/// pull d'une école d'effacer le barème d'une autre sur une tablette partagée.
///
/// Il est **stampé depuis `CurrentUserContext`**, jamais lu dans le payload :
/// même principe que `ref_academic_years`, et que `granted_by` côté serveur.
library;

/// Modèle de la table `ref_reduction_types` — une nature de réduction.
///
/// **Pas d'`id`** : `ReductionSummaryDto` n'en porte pas, et l'identité d'un
/// type est son [code] dans son école. En fabriquer un depuis ce couple aurait
/// rejoué côté client une identité que le contrat ne donne pas.
class ReductionTypeLocalModel {
  final String schoolId;
  final String code;
  final String label;
  final bool active;
  final int syncedAt;

  const ReductionTypeLocalModel({
    required this.schoolId,
    required this.code,
    required this.label,
    this.active = true,
    this.syncedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'school_id': schoolId,
    'code': code,
    'label': label,
    'active': active ? 1 : 0,
    'synced_at': syncedAt,
  };

  factory ReductionTypeLocalModel.fromMap(Map<String, Object?> m) =>
      ReductionTypeLocalModel(
        schoolId: (m['school_id'] as String?) ?? '',
        code: m['code'] as String,
        label: m['label'] as String,
        active: ((m['active'] as int?) ?? 1) != 0,
        syncedAt: (m['synced_at'] as int?) ?? 0,
      );
}

/// Modèle de la table `ref_reduction_lines` — ce qu'une nature réduit, et de
/// combien, rubrique par rubrique.
///
/// `percentage` est un pourcentage (0–100), pas de l'argent : d'où le `double`,
/// qui ne contredit pas la règle « argent = entier centimes ». Rien ne le
/// calcule en V1 — on stocke ce qui descend sans le réinterpréter.
///
/// [reductionCode] ne vient pas de la ligne : sur le fil elle est imbriquée
/// dans son type et ne porte que sa rubrique et son taux. C'est le code du
/// parent qui est stampé ici à l'aplatissement — le serveur a lui aussi choisi
/// la contrainte `(school_id, code)`, jamais un id de type.
class ReductionLineLocalModel {
  final String schoolId;
  final String reductionCode;
  final String feeCode;
  final double percentage;
  final int syncedAt;

  const ReductionLineLocalModel({
    required this.schoolId,
    required this.reductionCode,
    required this.feeCode,
    required this.percentage,
    this.syncedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'school_id': schoolId,
    'reduction_code': reductionCode,
    'fee_code': feeCode,
    'percentage': percentage,
    'synced_at': syncedAt,
  };

  factory ReductionLineLocalModel.fromMap(Map<String, Object?> m) =>
      ReductionLineLocalModel(
        schoolId: (m['school_id'] as String?) ?? '',
        reductionCode: m['reduction_code'] as String,
        feeCode: m['fee_code'] as String,
        percentage: (m['percentage'] as num).toDouble(),
        syncedAt: (m['synced_at'] as int?) ?? 0,
      );
}
