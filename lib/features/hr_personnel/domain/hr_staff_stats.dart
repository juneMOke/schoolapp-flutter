import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_name_order.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_seniority.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';

/// Femmes, hommes, et fiches dont le sexe n'est pas renseigné. Les trois
/// somment toujours à [total] : un sexe absent n'est jamais rangé d'office
/// d'un côté.
class HrSexSplit extends Equatable {
  final int women;
  final int men;
  final int unknown;

  const HrSexSplit({this.women = 0, this.men = 0, this.unknown = 0});

  int get total => women + men + unknown;

  HrSexSplit add(StaffSex? sex) => switch (sex) {
    StaffSex.female => HrSexSplit(women: women + 1, men: men, unknown: unknown),
    StaffSex.male => HrSexSplit(women: women, men: men + 1, unknown: unknown),
    null => HrSexSplit(women: women, men: men, unknown: unknown + 1),
  };

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
  final StaffMember member;
  final int years;

  const HrDean({required this.member, required this.years});

  @override
  List<Object?> get props => [member, years];
}

/// Les chiffres du tableau de bord RH · Personnel, calculés sur la tablette à
/// partir du fichier local — saisies hors ligne comprises — et jamais demandés
/// au serveur.
///
/// Ils portent sur **tout** le fichier : les filtres de la liste « Qui
/// sont-ils » ne les touchent pas.
class HrStaffStats extends Equatable {
  final int headcount;
  final HrSexSplit sexes;
  final int teachers;

  /// Moyenne des anciennetés entières, arrondie au dixième ; `null` quand
  /// aucun agent n'a de date d'entrée exploitable.
  ///
  /// Un agent sans date d'entrée lisible est **exclu**
  /// de la moyenne plutôt que compté pour zéro : zéro ferait baisser la
  /// moyenne d'une information qu'on n'a pas.
  final double? averageSeniority;

  /// Combien d'agents la moyenne porte.
  final int seniorityBase;
  final HrDean? dean;

  /// Les catégories non vides, dans l'ordre fixe enseignant → administratif →
  /// appui → non renseignée.
  final List<HrCategoryCount> categories;

  /// Fiches et pièces encore sur la tablette.
  final int pending;

  const HrStaffStats({
    required this.headcount,
    required this.sexes,
    required this.teachers,
    required this.averageSeniority,
    required this.seniorityBase,
    required this.dean,
    required this.categories,
    required this.pending,
  });

  factory HrStaffStats.of(StaffFileView view, {required String today}) {
    var sexes = const HrSexSplit();
    final byCategory = <HrCategoryKey, HrSexSplit>{};
    var seniorityTotal = 0;
    var seniorityBase = 0;
    StaffMember? dean;
    var deanYears = 0;

    for (final row in view.all) {
      final member = row.member;
      sexes = sexes.add(member.sex);
      final key = HrCategoryKey.of(member.category);
      byCategory[key] = (byCategory[key] ?? const HrSexSplit()).add(member.sex);

      final years = HrSeniority.yearsAt(member.entryDate, today);
      if (years == null) continue;
      seniorityTotal += years;
      seniorityBase++;
      if (dean == null || _enteredBefore(member, dean)) {
        dean = member;
        deanYears = years;
      }
    }

    return HrStaffStats(
      headcount: view.all.length,
      sexes: sexes,
      teachers: byCategory[HrCategoryKey.teacher]?.total ?? 0,
      averageSeniority: seniorityBase == 0
          ? null
          : (seniorityTotal * 10 / seniorityBase).round() / 10,
      seniorityBase: seniorityBase,
      dean: dean == null ? null : HrDean(member: dean, years: deanYears),
      categories: [
        for (final key in HrCategoryKey.values)
          if (byCategory[key] case final split?)
            HrCategoryCount(key: key, split: split),
      ],
      pending: view.pending,
    );
  }

  /// Part des enseignants, en pour cent entier ; 0 sur un fichier vide.
  int get teacherPercent =>
      headcount == 0 ? 0 : (teachers * 100 / headcount).round();

  /// L'entrée la plus ancienne gagne ; à date égale, l'ordre alphabétique.
  /// N'est appelé que sur des dates lisibles (ancienneté connue).
  static bool _enteredBefore(StaffMember candidate, StaffMember current) {
    final order = HrSeniority.entryOf(
      candidate.entryDate,
    )!.compareTo(HrSeniority.entryOf(current.entryDate)!);
    if (order != 0) return order < 0;
    return HrNameOrder.compare(candidate, current) < 0;
  }

  @override
  List<Object?> get props => [
    headcount,
    sexes,
    teachers,
    averageSeniority,
    seniorityBase,
    dean,
    categories,
    pending,
  ];
}
