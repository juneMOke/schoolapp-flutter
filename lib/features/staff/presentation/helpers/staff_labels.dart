import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés des valeurs fermées du fichier, en un seul endroit.
abstract final class StaffLabels {
  static String category(AppLocalizations l10n, StaffCategory category) =>
      switch (category) {
        StaffCategory.teacher => l10n.staffCategoryTeacher,
        StaffCategory.administrative => l10n.staffCategoryAdministrative,
        StaffCategory.support => l10n.staffCategorySupport,
      };

  /// `null` = aucun contrat en vigueur.
  static String contract(AppLocalizations l10n, StaffContractKind? kind) =>
      switch (kind) {
        StaffContractKind.permanent => l10n.staffContractPermanent,
        StaffContractKind.vacataire => l10n.staffContractVacataire,
        StaffContractKind.conventionne => l10n.staffContractConventionne,
        null => l10n.staffContractNone,
      };

  static String contractFilter(
    AppLocalizations l10n,
    StaffContractFilter filter,
  ) => switch (filter) {
    StaffContractFilter.permanent => l10n.staffContractPermanent,
    StaffContractFilter.vacataire => l10n.staffContractVacataire,
    StaffContractFilter.conventionne => l10n.staffContractConventionne,
    StaffContractFilter.none => l10n.staffContractNone,
  };
}
