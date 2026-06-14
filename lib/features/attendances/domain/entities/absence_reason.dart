import 'package:school_app_flutter/l10n/app_localizations.dart';

enum AbsenceReason {
  sickness,
  familyEmergency,
  personal,
  unknown,
  vacation,
  underGraduateLeave,
  marriageLeave,
  parentalLeave,
  workLeave,
  unjustified,
  other,
}

extension AbsenceReasonX on AbsenceReason {
  static AbsenceReason? fromApiValue(String? value) {
    if (value == null) return null;
    return switch (value.toUpperCase()) {
      'SICKNESS' => AbsenceReason.sickness,
      'FAMILY_EMERGENCY' => AbsenceReason.familyEmergency,
      'PERSONAL' => AbsenceReason.personal,
      'UNKNOWN' => AbsenceReason.unknown,
      'VACATION' => AbsenceReason.vacation,
      'UNDER_GRADUATE_LEAVE' => AbsenceReason.underGraduateLeave,
      'MARRIAGE_LEAVE' => AbsenceReason.marriageLeave,
      'PARENTAL_LEAVE' => AbsenceReason.parentalLeave,
      'WORK_LEAVE' => AbsenceReason.workLeave,
      'UNJUSTIFIED' => AbsenceReason.unjustified,
      'OTHER' => AbsenceReason.other,
      _ => AbsenceReason.unknown,
    };
  }

  String toApiValue() => switch (this) {
    AbsenceReason.sickness => 'SICKNESS',
    AbsenceReason.familyEmergency => 'FAMILY_EMERGENCY',
    AbsenceReason.personal => 'PERSONAL',
    AbsenceReason.unknown => 'UNKNOWN',
    AbsenceReason.vacation => 'VACATION',
    AbsenceReason.underGraduateLeave => 'UNDER_GRADUATE_LEAVE',
    AbsenceReason.marriageLeave => 'MARRIAGE_LEAVE',
    AbsenceReason.parentalLeave => 'PARENTAL_LEAVE',
    AbsenceReason.workLeave => 'WORK_LEAVE',
    AbsenceReason.unjustified => 'UNJUSTIFIED',
    AbsenceReason.other => 'OTHER',
  };

  /// Une absence est consideree injustifiee si son motif est `unjustified` ou
  /// `unknown` (motif inconnu / non renseigne cote backend). Regle metier
  /// partagee par l'ecran d'appel et la synthese de presence.
  bool get isUnjustified =>
      this == AbsenceReason.unjustified || this == AbsenceReason.unknown;

  /// Libelle localise du motif (reutilise les cles `absenceReason*`).
  String getDisplayName(AppLocalizations l10n) => switch (this) {
    AbsenceReason.sickness => l10n.absenceReasonSickness,
    AbsenceReason.familyEmergency => l10n.absenceReasonFamilyEmergency,
    AbsenceReason.personal => l10n.absenceReasonPersonal,
    AbsenceReason.unknown => l10n.absenceReasonUnknown,
    AbsenceReason.vacation => l10n.absenceReasonVacation,
    AbsenceReason.underGraduateLeave => l10n.absenceReasonUnderGraduateLeave,
    AbsenceReason.marriageLeave => l10n.absenceReasonMarriageLeave,
    AbsenceReason.parentalLeave => l10n.absenceReasonParentalLeave,
    AbsenceReason.workLeave => l10n.absenceReasonWorkLeave,
    AbsenceReason.unjustified => l10n.absenceReasonUnjustified,
    AbsenceReason.other => l10n.absenceReasonOther,
  };
}
