import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/fee_type_item.dart';

/// Miroir de `FeeTypeItemDto` — une ligne de la répartition par poste.
class FeeTypeItemModel {
  final String code;

  /// Tel qu'il descend du fil, **sans repli** : le modèle reste la copie exacte
  /// de la charge utile. C'est [toEntity] qui décide quoi montrer quand le
  /// serveur n'envoie rien.
  final String label;

  final int collected;
  final int expected;
  final int outstanding;
  final int collectionRate;

  const FeeTypeItemModel({
    required this.code,
    required this.label,
    required this.collected,
    required this.expected,
    required this.outstanding,
    required this.collectionRate,
  });

  factory FeeTypeItemModel.fromJson(Map<String, dynamic> json) {
    return FeeTypeItemModel(
      code: ((json['code'] as String?) ?? '').trim(),
      label: ((json['label'] as String?) ?? '').trim(),
      collected: (json['collected'] as num).toInt(),
      expected: (json['expected'] as num).toInt(),
      outstanding: (json['outstanding'] as num).toInt(),
      collectionRate: (json['collectionRate'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'label': label,
    'collected': collected,
    'expected': expected,
    'outstanding': outstanding,
    'collectionRate': collectionRate,
  };

  /// Le repli du libellé se fait **ici, une fois**, et non dans le widget.
  ///
  /// Le serveur envoie le libellé français de la nature ; s'il ne l'envoyait
  /// pas, l'écran montrerait un code brut plutôt qu'un vide — et surtout pas un
  /// libellé générique, sous lequel toutes les natures inconnues se
  /// confondraient.
  FeeTypeItem toEntity() => FeeTypeItem(
    code: code,
    label: label.isEmpty ? code : label,
    collected: collected,
    expected: expected,
    outstanding: outstanding,
    collectionRate: collectionRate,
  );
}
