import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Ce que la liste des élèves demande au serveur.
///
/// Les filtres sont **cumulatifs**, et tous facultatifs : sans eux, la liste est
/// celle de tous les bénéficiaires de la fenêtre.
class BeneficiariesQuery extends Equatable {
  /// Le plafond du serveur. Une page large, c'est aussi une photo hors ligne
  /// plus complète : c'est la première page qui se garde.
  static const int defaultPageSize = 100;

  final String academicYearId;
  final DashboardWindow window;
  final String? articleId;
  final String? classId;

  /// « Contient », plié en casse et en accents **côté serveur** : le `LOWER()`
  /// de SQLite ne plie pas les accents.
  final String? search;

  final int page;
  final int size;

  const BeneficiariesQuery({
    required this.academicYearId,
    required this.window,
    this.articleId,
    this.classId,
    this.search,
    this.page = 0,
    this.size = defaultPageSize,
  });

  /// Sans aucun filtre : c'est la seule page que le cache hors ligne garde.
  bool get isUnfiltered =>
      articleId == null &&
      classId == null &&
      (search == null || search!.trim().isEmpty);

  @override
  List<Object?> get props => [
    academicYearId,
    window,
    articleId,
    classId,
    search,
    page,
    size,
  ];
}
