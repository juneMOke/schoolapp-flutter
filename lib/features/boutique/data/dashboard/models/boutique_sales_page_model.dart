import 'package:school_app_flutter/features/boutique/data/dashboard/models/beneficiary_class_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_amounts_json.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_page.dart';

/// Miroir de la réponse de `GET /api/v1/boutique/sales`.
///
/// Lu sans `json_serializable`, comme la page des bénéficiaires : les montants
/// passent par [BoutiqueAmountsJson], la seule lecture du tableau
/// `[{amount, currency}]` du module.
abstract final class BoutiqueSalesPageModel {
  static BoutiqueSalesPage fromJson(Map<String, dynamic> json) =>
      BoutiqueSalesPage(
        totalElements: (json['totalElements'] as num).toInt(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 0,
        classes: [
          for (final raw in (json['classes'] as List<dynamic>? ?? const []))
            if (raw is Map<String, dynamic> && raw['id'] is String)
              BeneficiaryClassModel.fromJson(raw).toEntity(),
        ],
        // Une vente illisible fait échouer la page : l'écarter fausserait
        // `totalElements`, et la pagination annoncerait une ligne absente.
        items: [
          for (final raw in (json['items'] as List<dynamic>? ?? const []))
            _saleOf(raw as Map<String, dynamic>),
        ],
      );

  static BoutiqueSaleRow _saleOf(Map<String, dynamic> json) {
    final soldAt = json['soldAt'] as String;
    if (DateTime.tryParse(soldAt) == null) {
      throw FormatException('Heure de vente illisible : $soldAt');
    }
    return BoutiqueSaleRow(
      saleId: json['saleId'] as String,
      soldAt: soldAt,
      receiptNumber: _textOrNull(json['receiptNumber']),
      amounts: BoutiqueAmountsJson.fromJson(json['amounts']),
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      beneficiaries: [
        for (final raw in (json['beneficiaries'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic> && raw['studentId'] is String)
            SaleBeneficiary(
              studentId: raw['studentId'] as String,
              fullName: _textOrNull(raw['fullName']),
              classId: raw['classId'] as String?,
              classLabel: _textOrNull(raw['classLabel']),
            ),
      ],
      payerName: _textOrNull(json['payerName']),
    );
  }

  /// Un texte vide n'est pas un nom : il se lit comme absent.
  static String? _textOrNull(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw : null;
}
