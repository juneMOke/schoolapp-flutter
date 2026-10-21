import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Ce que la liste des élèves demande au serveur.
///
/// Les filtres sont **cumulatifs**, et tous facultatifs : sans eux, la liste est
/// celle de tous les bénéficiaires de la fenêtre.
class BeneficiariesQuery extends Equatable {
  /// Le plafond du serveur est 100 ; 50 suffit à couvrir une classe.
  static const int defaultPageSize = 50;

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

  BeneficiariesQuery nextPage() => BeneficiariesQuery(
    academicYearId: academicYearId,
    window: window,
    articleId: articleId,
    classId: classId,
    search: search,
    page: page + 1,
    size: size,
  );

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
