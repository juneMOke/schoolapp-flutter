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
    AbsenceReason.other => 'OTHER',
  };
}
