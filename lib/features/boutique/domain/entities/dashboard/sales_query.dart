import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';

/// Par quoi la liste des ventes se filtre — **l'un ou l'autre**, jamais les
/// deux : le serveur refuse le couple en 400, et l'écran ne propose qu'une
/// bascule.
enum SalesFilterMode { family, classroom }

/// Ce que la liste des ventes demande au serveur.
///
/// Le critère du mode **inactif** ne part jamais : [family] et [classId] ne
/// peuvent pas être posés ensemble, et le constructeur le vérifie.
class SalesQuery extends Equatable {
  /// La taille de page du contrat.
  static const int pageSize = 10;

  final String academicYearId;
  final DashboardWindow window;
  final ArticleFamily? family;
  final String? classId;
  final int page;

  const SalesQuery({
    required this.academicYearId,
    required this.window,
    this.family,
    this.classId,
    this.page = 0,
  }) : assert(
         family == null || classId == null,
         'SalesQuery : un critère à la fois, le serveur refuse les deux.',
       );

  bool get isFiltered => family != null || classId != null;

  /// La même question, sans pagination : celle que le rapport PDF pose.
  SalesQuery get firstPage => SalesQuery(
    academicYearId: academicYearId,
    window: window,
    family: family,
    classId: classId,
  );

  @override
  List<Object?> get props => [academicYearId, window, family, classId, page];
}
