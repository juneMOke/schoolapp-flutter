import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_kpis.dart';

class FinanceKpisModel {
  final int collected;
  final int expected;
  final int outstanding;
  final int collectionRate;

  const FinanceKpisModel({
    required this.collected,
    required this.expected,
    required this.outstanding,
    required this.collectionRate,
  });

  /// **Aucune tolérance ici, à l'inverse des sections.** Un `kpis` absent lève,
  /// et l'écran passe à l'erreur — un repli à zéro afficherait « 0 encaissé »
  /// sur un tableau de bord d'argent, ce qui se lit comme un résultat et non
  /// comme une lecture manquée.
  factory FinanceKpisModel.fromJson(Map<String, dynamic> json) {
    return FinanceKpisModel(
      collected: (json['collected'] as num).toInt(),
      expected: (json['expected'] as num).toInt(),
      outstanding: (json['outstanding'] as num).toInt(),
      collectionRate: (json['collectionRate'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'collected': collected,
    'expected': expected,
    'outstanding': outstanding,
    'collectionRate': collectionRate,
  };

  FinanceKpis toEntity() => FinanceKpis(
    collected: collected,
    expected: expected,
    outstanding: outstanding,
    collectionRate: collectionRate,
  );
}
