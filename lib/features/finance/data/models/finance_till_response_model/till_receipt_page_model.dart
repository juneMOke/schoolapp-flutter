import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_receipt_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipts_page.dart';

/// Miroir de `TillReceiptPageDto` — une page de la table des reçus.
///
/// **Enveloppe nommée, pas celle de Spring.** Le serveur a dû ajouter un champ
/// frère de `totalElements` (`withoutReceiptNumber`), ce que la sérialisation
/// de `Page<…>` ne permet pas ; il en a profité pour figer une forme qui ne
/// dépend plus de la version du framework. Conséquence pour ce modèle :
/// **`number` s'appelle désormais `page`**.
class TillReceiptPageModel {
  final List<TillReceiptModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final int withoutReceiptNumber;

  /// L'année de la fenêtre. Nullable : elle n'arrive qu'avec la version du
  /// contrat qui l'ajoute, et son absence doit laisser la table se lire.
  final String? academicYearId;

  const TillReceiptPageModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.withoutReceiptNumber,
    this.academicYearId,
  });

  /// Les compteurs cèdent à zéro, `content` à une liste vide : une page est une
  /// **tranche**, et une tranche illisible vaut mieux vide qu'inventée. Les
  /// lignes elles-mêmes, en revanche, gardent leurs propres exigences — un
  /// montant absent y lève.
  factory TillReceiptPageModel.fromJson(Map<String, dynamic> json) {
    return TillReceiptPageModel(
      content: [
        for (final item in json['content'] as List<dynamic>? ?? const [])
          if (item is Map<String, dynamic>) TillReceiptModel.fromJson(item),
      ],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      // Absent ⇒ 0 ⇒ le sous-titre tait la mention. Un serveur qui ne le sert
      // pas encore ne doit pas faire annoncer un compte inventé.
      withoutReceiptNumber:
          (json['withoutReceiptNumber'] as num?)?.toInt() ?? 0,
      // Absent ⇒ `null` ⇒ aucun œil ne s'allume. Un serveur qui ne la sert pas
      // encore ne doit pas faire pousser une route à laquelle il manque un
      // paramètre.
      academicYearId: switch (json['academicYearId']) {
        final String raw when raw.trim().isNotEmpty => raw.trim(),
        _ => null,
      },
    );
  }

  TillReceiptsPage toEntity() => TillReceiptsPage(
    content: [for (final item in content) item.toEntity()],
    page: page,
    size: size,
    totalElements: totalElements,
    totalPages: totalPages,
    withoutReceiptNumber: withoutReceiptNumber,
    academicYearId: academicYearId,
  );
}
