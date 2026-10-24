import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';

/// Femmes, hommes, et fiches dont le sexe n'est pas renseigné. Les trois
/// somment toujours à [total] : un sexe absent n'est jamais rangé d'office
/// d'un côté.
class HrSexSplit extends Equatable {
  final int women;
  final int men;
  final int unknown;

  const HrSexSplit({this.women = 0, this.men = 0, this.unknown = 0});

  int get total => women + men + unknown;

  @override
  List<Object?> get props => [women, men, unknown];
}

/// Une catégorie non vide : combien d'agents, et leur parité.
class HrCategoryCount extends Equatable {
  final HrCategoryKey key;
  final HrSexSplit split;

  const HrCategoryCount({required this.key, required this.split});

  int get count => split.total;

  @override
  List<Object?> get props => [key, split];
}

/// Le doyen : l'agent entré le premier, et depuis combien d'années.
class HrDean extends Equatable {
  final String staffMemberId;
  final String lastName;
  final String? middleName;
  final String? firstName;
  final String entryDate;
  final int years;

  const HrDean({
    required this.staffMemberId,
    required this.lastName,
    required this.middleName,
    required this.firstName,
    required this.entryDate,
    required this.years,
  });

  /// « Béatrice MBUYI » : prénom puis nom, comme la ligne du doyen l'écrit.
  String get displayName => [
    firstName?.trim() ?? '',
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    staffMemberId,
    lastName,
    middleName,
    firstName,
    entryDate,
    years,
  ];
}

/// Les chiffres du tableau de bord RH · Personnel, **calculés par le serveur**
/// (`GET /hr/staff-stats`) au jour de l'école [asOf], sur les seules fiches
/// déjà remontées : la même source que la liste et le PDF, pour que l'écran et
/// le papier ne divergent jamais. Ce que la tablette n'a pas encore envoyé se
/// dit à part.
///
/// Ils portent sur **tout** le personnel : les filtres de la liste « Qui
/// sont-ils » ne les touchent pas.
class HrStaffStats extends Equatable {
  /// Le jour de l'école, `YYYY-MM-DD`.
  final String asOf;
  final int headcount;
  final HrSexSplit sexes;

  /// Moyenne des anciennetés en années révolues, au dixième ; `null` quand
  /// aucun agent n'a de date d'entrée. Un agent sans date est **exclu** de la
  /// moyenne plutôt que compté pour zéro.
  final double? averageSeniority;

  /// Combien d'agents la moyenne porte.
  final int seniorityBase;
  final HrDean? dean;

  /// Les catégories non vides, dans l'ordre fixe enseignant → administratif →
  /// appui.
  final List<HrCategoryCount> categories;

  const HrStaffStats({
    required this.asOf,
    required this.headcount,
    required this.sexes,
    required this.averageSeniority,
    required this.seniorityBase,
    required this.dean,
    required this.categories,
  });

  int get teachers => countOf(HrCategoryKey.teacher);

  /// L'effectif de [key] ; zéro pour une catégorie vide.
  int countOf(HrCategoryKey key) =>
      categories.where((c) => c.key == key).firstOrNull?.count ?? 0;

  /// Part des enseignants, en pour cent entier ; 0 sur un fichier vide.
  int get teacherPercent =>
      headcount == 0 ? 0 : (teachers * 100 / headcount).round();

  @override
  List<Object?> get props => [
    asOf,
    headcount,
    sexes,
    averageSeniority,
    seniorityBase,
    dean,
    categories,
  ];
}
