import 'package:school_app_flutter/features/boutique/data/dashboard/models/beneficiary_class_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_beneficiary_model.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';

/// Miroir de la réponse de `GET /api/v1/boutique/beneficiaries` (R9).
class BoutiqueBeneficiariesPageModel {
  final int totalElements;
  final int page;
  final int size;
  final List<BeneficiaryClassModel> classes;
  final int walkInLineCount;
  final List<BoutiqueBeneficiaryModel> items;

  const BoutiqueBeneficiariesPageModel({
    required this.totalElements,
    required this.page,
    required this.size,
    this.classes = const [],
    this.walkInLineCount = 0,
    this.items = const [],
  });

  factory BoutiqueBeneficiariesPageModel.fromJson(Map<String, dynamic> json) =>
      BoutiqueBeneficiariesPageModel(
        totalElements: (json['totalElements'] as num).toInt(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 0,
        classes: [
          for (final raw in (json['classes'] as List<dynamic>? ?? const []))
            if (raw is Map<String, dynamic> && raw['id'] is String)
              BeneficiaryClassModel.fromJson(raw),
        ],
        walkInLineCount: (json['walkInLineCount'] as num?)?.toInt() ?? 0,
        // Un élève illisible fait échouer la page : l'écarter fausserait
        // `totalElements`, et « Voir les 38 élèves » n'en montrerait que 37.
        items: [
          for (final raw in (json['items'] as List<dynamic>? ?? const []))
            BoutiqueBeneficiaryModel.fromJson(raw as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'totalElements': totalElements,
    'page': page,
    'size': size,
    'classes': [for (final c in classes) c.toJson()],
    'walkInLineCount': walkInLineCount,
    'items': [for (final item in items) item.toJson()],
  };

  BoutiqueBeneficiariesPage toEntity() => BoutiqueBeneficiariesPage(
    totalElements: totalElements,
    page: page,
    size: size,
    classes: [for (final c in classes) c.toEntity()],
    walkInLineCount: walkInLineCount,
    items: [for (final item in items) item.toEntity()],
  );
}
