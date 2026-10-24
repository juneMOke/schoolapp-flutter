import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_name_order.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_seniority.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';

/// L'ordre d'une liste du personnel.
enum HrRosterSort {
  /// Alphabétique : nom, post-nom, prénom.
  name,

  /// Alphabétique inversé — l'en-tête « Agent » du Fichier, touché une fois.
  nameDescending,

  /// Les plus anciens d'abord (date d'entrée croissante).
  oldest,

  /// Les plus récents d'abord (date d'entrée décroissante).
  newest,
}

/// Les critères d'une liste du personnel : recherche, catégorie, ordre. Tout
/// se recalcule en mémoire, sans jamais relire la base.
class HrRosterQuery extends Equatable {
  final String text;

  /// `null` = toutes les catégories.
  final HrCategoryKey? category;
  final HrRosterSort sort;

  const HrRosterQuery({
    this.text = '',
    this.category,
    this.sort = HrRosterSort.name,
  });

  static const HrRosterQuery none = HrRosterQuery();

  bool get hasText => text.trim().isNotEmpty;

  /// Un filtre réduit-il la liste ? L'ordre, lui, ne retire personne.
  bool get isFiltering => hasText || category != null;

  HrRosterQuery withText(String value) =>
      HrRosterQuery(text: value, category: category, sort: sort);

  HrRosterQuery withCategory(HrCategoryKey? value) =>
      HrRosterQuery(text: text, category: value, sort: sort);

  /// Un second tap sur la catégorie active la retire.
  HrRosterQuery toggleCategory(HrCategoryKey value) =>
      withCategory(value == category ? null : value);

  HrRosterQuery withSort(HrRosterSort value) =>
      HrRosterQuery(text: text, category: category, sort: value);

  /// Vide la recherche et la catégorie ; garde l'ordre choisi.
  HrRosterQuery cleared() => HrRosterQuery(sort: sort);

  bool accepts(StaffFileRow row) {
    if (category != null && HrCategoryKey.of(row.member.category) != category) {
      return false;
    }
    return StaffMemberSearch.matches(row.member, text);
  }

  /// Les lignes de [rows] qui passent les filtres, dans l'ordre demandé.
  List<StaffFileRow> apply(Iterable<StaffFileRow> rows) => [
    for (final row in rows)
      if (accepts(row)) row,
  ]..sort(_compare);

  int _compare(StaffFileRow a, StaffFileRow b) => switch (sort) {
    HrRosterSort.name => HrNameOrder.compare(a.member, b.member),
    HrRosterSort.nameDescending => HrNameOrder.compare(b.member, a.member),
    HrRosterSort.oldest => _byEntry(a, b, ascending: true),
    HrRosterSort.newest => _byEntry(a, b, ascending: false),
  };

  /// Par date d'entrée ; une date absente ou illisible va **en fin de liste**
  /// dans les deux sens — elle ne dit ni « ancien » ni « récent ». À date
  /// égale, l'ordre alphabétique.
  static int _byEntry(
    StaffFileRow a,
    StaffFileRow b, {
    required bool ascending,
  }) {
    final left = HrSeniority.entryOf(a.member.entryDate);
    final right = HrSeniority.entryOf(b.member.entryDate);
    if (left != right) {
      if (left == null) return 1;
      if (right == null) return -1;
      final order = left.compareTo(right);
      return ascending ? order : -order;
    }
    return HrNameOrder.compare(a.member, b.member);
  }

  @override
  List<Object?> get props => [text, category, sort];
}
