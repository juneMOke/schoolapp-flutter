import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';

/// Les écrans de la trésorerie tenus dans leur adresse : F5 rouvre la même
/// journée, la même période, la même page de rapports ; l'adresse se
/// partage. Les valeurs par défaut laissent l'adresse nue.
///
/// - Clôture : `?vue=semaine&debut=2026-10-12`, `?jour=2026-10-12`.
/// - Tableau de bord : `?evolution=custom&evolution-du=…&evolution-au=…`,
///   `?rapports=weekly&rapports-page=2`.
abstract final class TreasuryLocation {
  static const viewParam = 'vue';
  static const dayParam = 'jour';
  static const periodParam = 'debut';
  static const weekValue = 'semaine';
  static const monthValue = 'mois';

  static const evolutionParam = 'evolution';
  static const evolutionFromParam = 'evolution-du';
  static const evolutionToParam = 'evolution-au';
  static const reportsParam = 'rapports';
  static const reportsPageParam = 'rapports-page';

  static String? viewOf(ClosingScope scope) => switch (scope) {
    ClosingScope.day => null,
    ClosingScope.week => weekValue,
    ClosingScope.month => monthValue,
  };

  static ClosingScope scopeOf(String? value) => switch (value) {
    weekValue => ClosingScope.week,
    monthValue => ClosingScope.month,
    _ => ClosingScope.day,
  };

  /// `2026-10-12` → le 12 octobre ; `null` pour une valeur illisible.
  static DateTime? dayOf(String? value) =>
      value != null && SchoolDayCalendar.isDay(value)
      ? DateTime.parse(value)
      : null;

  static String? write(DateTime? day) =>
      day == null ? null : SchoolDayCalendar.dayOf(day);

  static EvolutionPeriod evolutionOf(String? value) =>
      EvolutionPeriod.values.where((p) => p.name == value).firstOrNull ??
      defaultEvolution;

  static const defaultEvolution = EvolutionPeriod.month;

  static CashReportKind reportKindOf(String? value) =>
      CashReportKind.values.where((k) => k.name == value).firstOrNull ??
      defaultReportKind;

  static const defaultReportKind = CashReportKind.daily;

  /// `rapports-page=2` → l'index 1 ; la première page pour le reste.
  static int pageOf(String? value) {
    final page = int.tryParse(value ?? '');
    return page == null || page < 1 ? 0 : page - 1;
  }

  static String? writePage(int index) => index <= 0 ? null : '${index + 1}';
}
