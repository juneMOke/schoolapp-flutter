import 'package:flutter/painting.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_seniority.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés et teintes du module RH · Personnel, en un seul endroit : la
/// liste, les barres et le PDF disent la même chose avec les mêmes mots.
abstract final class HrPersonnelLabels {
  static String category(AppLocalizations l10n, HrCategoryKey key) {
    final category = key.category;
    return category == null
        ? l10n.hrCategoryUnknown
        : StaffLabels.category(l10n, category);
  }

  /// Teinte de la barre d'une catégorie.
  static Color categoryColor(HrCategoryKey key) => switch (key) {
    HrCategoryKey.teacher => AppColors.hrCategoryTeacher,
    HrCategoryKey.administrative => AppColors.hrCategoryAdministrative,
    HrCategoryKey.support => AppColors.hrCategorySupport,
    HrCategoryKey.unknown => AppColors.hrCategoryUnknown,
  };

  /// Encre du libellé d'une catégorie, lisible sur blanc.
  static Color categoryInk(HrCategoryKey key) => switch (key) {
    HrCategoryKey.teacher => AppColors.hrCategoryTeacherInk,
    HrCategoryKey.administrative => AppColors.hrCategoryAdministrativeInk,
    HrCategoryKey.support => AppColors.hrCategorySupportInk,
    HrCategoryKey.unknown => AppColors.hrCategoryUnknownInk,
  };

  /// « 3 ans », « moins d'1 an », ou « entrée non renseignée ».
  static String seniority(
    AppLocalizations l10n, {
    required String? entryDate,
    required String today,
  }) {
    final years = HrSeniority.yearsAt(entryDate, today);
    return years == null
        ? l10n.hrSeniorityUnknown
        : l10n.hrSeniorityYears(years);
  }

  /// « 09/2018 » depuis `2018-09-01` ; `null` si la date ne se lit pas.
  static String? monthYear(String? day) {
    final date = HrSeniority.entryOf(day);
    if (date == null) return null;
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// « 15/09/2023 » depuis `2023-09-15` ; `null` si la date ne se lit pas.
  static String? dayMonthYear(String? day) {
    final date = HrSeniority.entryOf(day);
    if (date == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  /// La moyenne au dixième, avec le séparateur de la langue (« 7,6 »).
  static String decimal(AppLocalizations l10n, double value) {
    final tenths = (value * 10).round();
    return l10n.hrDecimal(tenths ~/ 10, tenths % 10);
  }

  /// Ce que la liste montre : la catégorie et/ou « recherche », sinon « tout le
  /// personnel ». Le sous-titre de la liste, le vide filtré et le PDF la
  /// partagent.
  static String scope(AppLocalizations l10n, HrRosterQuery query) {
    final category = query.category;
    final parts = [
      if (category != null) HrPersonnelLabels.category(l10n, category),
      if (query.hasText) l10n.hrRosterScopeSearch,
    ];
    return switch (parts) {
      [] => l10n.hrRosterScopeAll,
      [final only] => only,
      [final first, final second, ...] => l10n.hrJoin(first, second),
    };
  }

  static String sort(AppLocalizations l10n, HrRosterSort sort) =>
      switch (sort) {
        HrRosterSort.name => l10n.hrSortName,
        HrRosterSort.nameDescending => l10n.hrSortNameDescending,
        HrRosterSort.oldest => l10n.hrSortOldest,
        HrRosterSort.newest => l10n.hrSortNewest,
      };

  /// Le tri tel que le PDF l'imprime (« trié par nom »).
  static String pdfSort(AppLocalizations l10n, HrRosterSort sort) =>
      switch (sort) {
        HrRosterSort.name => l10n.hrPdfSortName,
        HrRosterSort.nameDescending => l10n.hrPdfSortNameDescending,
        HrRosterSort.oldest => l10n.hrPdfSortOldest,
        HrRosterSort.newest => l10n.hrPdfSortNewest,
      };
}
