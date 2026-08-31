import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

/// Un article du catalogue tel qu'il est stocké localement.
///
/// Porte `family` et `pricingMode` en **chaîne**, pas en enum : la base garde ce
/// que le serveur a servi, y compris une valeur que cette version du client ne
/// connaît pas encore. La traduction — et la décision sur l'inconnu — se fait au
/// passage vers le domaine, dans [toEntity].
class BoutiqueArticleLocalModel {
  final String id;
  final String academicYearId;
  final String code;
  final String label;
  final String family;
  final String pricingMode;
  final int? unitPriceInCents;
  final Map<String, int> levelPrices;
  final String currency;

  const BoutiqueArticleLocalModel({
    required this.id,
    required this.academicYearId,
    required this.code,
    required this.label,
    required this.family,
    required this.pricingMode,
    this.unitPriceInCents,
    this.levelPrices = const {},
    required this.currency,
  });

  Map<String, Object?> toMap({required String schoolId}) => {
    'id': id,
    'school_id': schoolId,
    'academic_year_id': academicYearId,
    'code': code,
    'label': label,
    'family': family,
    'pricing_mode': pricingMode,
    'unit_price_in_cents': unitPriceInCents,
    'currency': currency,
    'updated_at': DateTime.now().millisecondsSinceEpoch,
  };

  factory BoutiqueArticleLocalModel.fromMap(
    Map<String, Object?> map, {
    Map<String, int> levelPrices = const {},
  }) => BoutiqueArticleLocalModel(
    id: map['id'] as String,
    academicYearId: map['academic_year_id'] as String,
    code: map['code'] as String,
    label: map['label'] as String,
    family: map['family'] as String,
    pricingMode: map['pricing_mode'] as String,
    unitPriceInCents: (map['unit_price_in_cents'] as num?)?.toInt(),
    levelPrices: levelPrices,
    currency: map['currency'] as String,
  );

  /// Vers le domaine — **dans le repository**, jamais dans un BLoC.
  ///
  /// `family` et `pricingMode` inconnus deviennent `null`, avec deux
  /// conséquences très différentes que l'entité porte : une famille inconnue
  /// laisse l'article vendable (son prix n'en dépend pas), un mode inconnu le
  /// rend invendable — le replier sur « prix unique » le vendrait sans demander
  /// le niveau.
  BoutiqueArticle toEntity() => BoutiqueArticle(
    id: id,
    academicYearId: academicYearId,
    code: code,
    label: label,
    family: ArticleFamily.fromWire(family),
    pricingMode: PricingMode.fromWire(pricingMode),
    unitPriceInCents: unitPriceInCents,
    levelPrices: levelPrices,
    currency: currency,
  );
}
