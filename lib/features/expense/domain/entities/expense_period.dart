import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';

/// La taille de la fenêtre consultée.
///
/// ⚠️ `schoolYear` et non « année civile » : décision D2 du plan back — les
/// Encaissements et le Recouvrement comptent déjà de la rentrée à la rentrée,
/// et la direction confronte recettes et dépenses sur la **même** année.
enum ExpenseGranularity { day, week, month, schoolYear }

/// La période consultée : une granularité et un pas, `0` = la période en
/// cours, `-1` la précédente… Jamais positif : l'école ne consulte pas ses
/// dépenses futures.
class ExpensePeriod extends Equatable {
  final ExpenseGranularity granularity;
  final int offset;

  const ExpensePeriod({
    this.granularity = ExpenseGranularity.month,
    this.offset = 0,
  }) : assert(offset <= 0, 'Une période ne va jamais dans le futur.');

  /// Le défaut de l'écran : le mois en cours.
  static const initial = ExpensePeriod();

  /// Le mois qui contient [day], vu depuis [today] : « Voir le mois entier »
  /// depuis une journée ou une semaine passée ouvre SON mois, pas le mois en
  /// cours.
  factory ExpensePeriod.monthOf(DateTime day, {required DateTime today}) {
    final offset = (day.year - today.year) * 12 + day.month - today.month;
    return ExpensePeriod(offset: offset > 0 ? 0 : offset);
  }

  bool get isCurrent => offset == 0;

  /// Une journée ou une semaine : la fenêtre peut s'élargir à son mois.
  bool get canWidenToMonth =>
      granularity == ExpenseGranularity.day ||
      granularity == ExpenseGranularity.week;

  bool get canGoForward => offset < 0;

  /// Changer de maille repart de la période en cours : un décalage hérité
  /// n'a pas de sens dans la nouvelle maille.
  ExpensePeriod withGranularity(ExpenseGranularity value) =>
      ExpensePeriod(granularity: value);

  ExpensePeriod previous() =>
      ExpensePeriod(granularity: granularity, offset: offset - 1);

  /// Borné à la période en cours.
  ExpensePeriod next() => canGoForward
      ? ExpensePeriod(granularity: granularity, offset: offset + 1)
      : this;

  ExpensePeriod current() => ExpensePeriod(granularity: granularity);

  @override
  List<Object?> get props => [granularity, offset];
}

/// Un intervalle de **jours**, bornes incluses.
class ExpenseDateRange extends Equatable {
  final DateTime from;
  final DateTime to;

  ExpenseDateRange({required DateTime from, required DateTime to})
    : from = ExpenseDay.of(from),
      to = ExpenseDay.of(to);

  /// `YYYY-MM-DD` de la borne basse — comparable à `expense_date`.
  String get fromKey => ExpenseDay.format(from);

  String get toKey => ExpenseDay.format(to);

  int get dayCount => ExpenseDay.spanInclusive(from, to);

  /// Appartenance par **jour**, jamais par horodatage.
  bool containsKey(String dayKey) =>
      dayKey.compareTo(fromKey) >= 0 && dayKey.compareTo(toKey) <= 0;

  bool contains(DateTime day) => containsKey(ExpenseDay.format(day));

  @override
  List<Object?> get props => [from, to];
}

/// Le jour de rentrée qui ouvre chaque année scolaire.
class SchoolYearAnchor extends Equatable {
  final int month;
  final int day;

  const SchoolYearAnchor({required this.month, required this.day});

  /// Repli quand le référentiel ne date pas l'année courante : l'année
  /// scolaire congolaise court de septembre à août.
  static const september = SchoolYearAnchor(month: DateTime.september, day: 1);

  /// L'ancre d'une année datée ; `null` ⇒ [september].
  factory SchoolYearAnchor.fromStartDate(DateTime? startDate) =>
      startDate == null
      ? september
      : SchoolYearAnchor(month: startDate.month, day: startDate.day);

  @override
  List<Object?> get props => [month, day];
}
