import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';

part 'fee_code_model.g.dart';

/// Une section de frais servie par `GET /finance/fee-codes`.
///
/// Le libellé peut manquer : on se rabat alors sur le code, qui est toujours
/// affichable — mieux vaut « CANTEEN » qu'une ligne vide dans un sélecteur.
///
/// `active` et `sortOrder` sont **tolérés absents** : un serveur antérieur à
/// V115 ne les sert pas, et l'application doit continuer de fonctionner devant
/// lui. Tout est alors visible, et le rang est celui de la position servie —
/// c'est-à-dire exactement le comportement d'avant.
@JsonSerializable(createToJson: false)
class FeeCodeModel {
  @JsonKey(defaultValue: '')
  final String code;

  final String? label;

  final bool? active;

  final int? sortOrder;

  const FeeCodeModel({
    required this.code,
    required this.label,
    this.active,
    this.sortOrder,
  });

  factory FeeCodeModel.fromJson(Map<String, dynamic> json) =>
      _$FeeCodeModelFromJson(json);

  /// [fallbackSortOrder] est la position servie : le serveur trie déjà, donc
  /// s'en remettre à l'ordre reçu ne perd rien.
  FeeCodeOption toEntity({required int fallbackSortOrder}) => FeeCodeOption(
    code: code,
    label: (label == null || label!.trim().isEmpty) ? code : label!.trim(),
    active: active ?? true,
    sortOrder: sortOrder ?? fallbackSortOrder,
  );
}

/// Une décision de nommage, telle que `POST /finance/fee-codes` l'attend.
///
/// **Chaque champ est indépendamment facultatif**, seul `code` est requis :
/// masquer une section s'écrit sans réémettre son titre. Un champ absent laisse
/// la valeur en place — il ne la remet pas au défaut.
@JsonSerializable(createFactory: false, includeIfNull: false)
class FeeCodeSectionInputModel {
  final String code;
  final String? label;
  final bool? active;
  final int? sortOrder;

  const FeeCodeSectionInputModel({
    required this.code,
    this.label,
    this.active,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() => _$FeeCodeSectionInputModelToJson(this);
}

/// Le lot : un geste, pas une série d'appels.
///
/// Le reclassement est un lot par nature — un glisser-déposer déplace une
/// section et en décale cinq autres. Les envoyer une par une laisserait l'écran
/// dans un ordre intermédiaire que personne n'a voulu.
@JsonSerializable(createFactory: false)
class FeeCodeSectionsPayloadModel {
  final List<FeeCodeSectionInputModel> sections;

  const FeeCodeSectionsPayloadModel({required this.sections});

  Map<String, dynamic> toJson() => _$FeeCodeSectionsPayloadModelToJson(this);
}
