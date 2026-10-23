import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_class.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';

/// Une page de ventes — la réponse de `GET /boutique/sales`.
class BoutiqueSalesPage extends Equatable {
  /// Calculé **après** le filtre.
  final int totalElements;

  /// 0-based, comme le serveur.
  final int page;
  final int size;

  /// Les classes des élèves de la fenêtre, calculées **avant** le filtre de
  /// classe : le menu ne se vide pas dès qu'on y choisit une classe.
  final List<BeneficiaryClass> classes;

  final List<BoutiqueSaleRow> items;

  const BoutiqueSalesPage({
    required this.totalElements,
    required this.page,
    required this.size,
    this.classes = const [],
    this.items = const [],
  });

  int get totalPages =>
      size <= 0 || totalElements == 0 ? 1 : (totalElements + size - 1) ~/ size;

  @override
  List<Object?> get props => [totalElements, page, size, classes, items];
}
