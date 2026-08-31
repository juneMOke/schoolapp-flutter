import 'package:equatable/equatable.dart';

/// Un tarif tel qu'il existe en base après l'activation.
///
/// **Un tarif porte UN niveau.** La notion d'assiette de l'étape 4 n'existe plus
/// ici : ce que l'assistant saisissait comme « un minerval sur vingt niveaux »
/// est devenu vingt lignes, chacune avec son identifiant. Les modifier ensemble
/// n'est pas offert — et ne doit pas l'être tant que le serveur n'a pas de geste
/// pour ça, sinon l'écran promettrait une atomicité qu'il ne peut pas tenir.
class FeeTariff extends Equatable {
  final String id;
  final String feeCode;
  final String label;
  final int amountInCents;
  final String currency;
  final DateTime? dueAt;
  final String schoolLevelId;
  final String? schoolLevelGroupId;

  const FeeTariff({
    required this.id,
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [
    id,
    feeCode,
    label,
    amountInCents,
    currency,
    dueAt,
    schoolLevelId,
    schoolLevelGroupId,
  ];
}

/// Ce qu'il faut pour créer ou remplacer un tarif.
class FeeTariffDraft extends Equatable {
  final String feeCode;
  final String label;
  final int amountInCents;
  final String currency;
  final DateTime? dueAt;
  final String schoolLevelId;
  final String schoolLevelGroupId;
  final String academicYearId;

  const FeeTariffDraft({
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [
    feeCode,
    label,
    amountInCents,
    currency,
    dueAt,
    schoolLevelId,
    schoolLevelGroupId,
    academicYearId,
  ];
}
