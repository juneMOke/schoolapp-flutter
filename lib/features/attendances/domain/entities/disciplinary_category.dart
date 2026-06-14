import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinaryCategory {
  disruptiveBehavior,
  lateness,
  repeatedLateness,
  unjustifiedAbsence,
  insolence,
  cheating,
  fighting,
  dressCodeViolation,
  talkingInClass,
  unknown,
}

extension DisciplinaryCategoryX on DisciplinaryCategory {
  static DisciplinaryCategory fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'DISRUPTIVE_BEHAVIOR' => DisciplinaryCategory.disruptiveBehavior,
        'LATENESS' => DisciplinaryCategory.lateness,
        'REPEATED_LATENESS' => DisciplinaryCategory.repeatedLateness,
        'UNJUSTIFIED_ABSENCE' => DisciplinaryCategory.unjustifiedAbsence,
        'INSOLENCE' => DisciplinaryCategory.insolence,
        'CHEATING' => DisciplinaryCategory.cheating,
        'FIGHTING' => DisciplinaryCategory.fighting,
        'DRESS_CODE_VIOLATION' => DisciplinaryCategory.dressCodeViolation,
        'TALKING_IN_CLASS' => DisciplinaryCategory.talkingInClass,
        _ => DisciplinaryCategory.unknown,
      };

  String toApiValue() => switch (this) {
    DisciplinaryCategory.disruptiveBehavior => 'DISRUPTIVE_BEHAVIOR',
    DisciplinaryCategory.lateness => 'LATENESS',
    DisciplinaryCategory.repeatedLateness => 'REPEATED_LATENESS',
    DisciplinaryCategory.unjustifiedAbsence => 'UNJUSTIFIED_ABSENCE',
    DisciplinaryCategory.insolence => 'INSOLENCE',
    DisciplinaryCategory.cheating => 'CHEATING',
    DisciplinaryCategory.fighting => 'FIGHTING',
    DisciplinaryCategory.dressCodeViolation => 'DRESS_CODE_VIOLATION',
    DisciplinaryCategory.talkingInClass => 'TALKING_IN_CLASS',
    DisciplinaryCategory.unknown => 'UNKNOWN',
  };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
    DisciplinaryCategory.disruptiveBehavior =>
      l10n.disciplinaryCategoryDisruptiveBehavior,
    DisciplinaryCategory.lateness => l10n.disciplinaryCategoryLateness,
    DisciplinaryCategory.repeatedLateness =>
      l10n.disciplinaryCategoryRepeatedLateness,
    DisciplinaryCategory.unjustifiedAbsence =>
      l10n.disciplinaryCategoryUnjustifiedAbsence,
    DisciplinaryCategory.insolence => l10n.disciplinaryCategoryInsolence,
    DisciplinaryCategory.cheating => l10n.disciplinaryCategoryCheating,
    DisciplinaryCategory.fighting => l10n.disciplinaryCategoryFighting,
    DisciplinaryCategory.dressCodeViolation =>
      l10n.disciplinaryCategoryDressCodeViolation,
    DisciplinaryCategory.talkingInClass =>
      l10n.disciplinaryCategoryTalkingInClass,
    DisciplinaryCategory.unknown => l10n.disciplinaryCategoryUnknown,
  };

  /// Gravité par défaut servant de gabarit dans la modale (cf. spec MÉTIER-8).
  DisciplinarySeverity get defaultSeverity => switch (this) {
    DisciplinaryCategory.fighting => DisciplinarySeverity.serious,
    DisciplinaryCategory.unjustifiedAbsence ||
    DisciplinaryCategory.insolence ||
    DisciplinaryCategory.cheating => DisciplinarySeverity.major,
    _ => DisciplinarySeverity.minor,
  };
}
