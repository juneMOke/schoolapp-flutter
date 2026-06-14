import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinarySanction {
  oralWarning,
  writtenWarning,
  detention,
  parentsSummoned,
  temporaryExclusion,
  disciplinaryCouncil,
  permanentExclusion,
  unknown,
}

extension DisciplinarySanctionX on DisciplinarySanction {
  static DisciplinarySanction fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'ORAL_WARNING' => DisciplinarySanction.oralWarning,
        'WRITTEN_WARNING' => DisciplinarySanction.writtenWarning,
        'DETENTION' => DisciplinarySanction.detention,
        'PARENTS_SUMMONED' => DisciplinarySanction.parentsSummoned,
        'TEMPORARY_EXCLUSION' => DisciplinarySanction.temporaryExclusion,
        'DISCIPLINARY_COUNCIL' => DisciplinarySanction.disciplinaryCouncil,
        'PERMANENT_EXCLUSION' => DisciplinarySanction.permanentExclusion,
        _ => DisciplinarySanction.unknown,
      };

  String toApiValue() => switch (this) {
    DisciplinarySanction.oralWarning => 'ORAL_WARNING',
    DisciplinarySanction.writtenWarning => 'WRITTEN_WARNING',
    DisciplinarySanction.detention => 'DETENTION',
    DisciplinarySanction.parentsSummoned => 'PARENTS_SUMMONED',
    DisciplinarySanction.temporaryExclusion => 'TEMPORARY_EXCLUSION',
    DisciplinarySanction.disciplinaryCouncil => 'DISCIPLINARY_COUNCIL',
    DisciplinarySanction.permanentExclusion => 'PERMANENT_EXCLUSION',
    DisciplinarySanction.unknown => 'UNKNOWN',
  };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
    DisciplinarySanction.oralWarning => l10n.disciplinarySanctionOralWarning,
    DisciplinarySanction.writtenWarning =>
      l10n.disciplinarySanctionWrittenWarning,
    DisciplinarySanction.detention => l10n.disciplinarySanctionDetention,
    DisciplinarySanction.parentsSummoned =>
      l10n.disciplinarySanctionParentsSummoned,
    DisciplinarySanction.temporaryExclusion =>
      l10n.disciplinarySanctionTemporaryExclusion,
    DisciplinarySanction.disciplinaryCouncil =>
      l10n.disciplinarySanctionDisciplinaryCouncil,
    DisciplinarySanction.permanentExclusion =>
      l10n.disciplinarySanctionPermanentExclusion,
    DisciplinarySanction.unknown => l10n.disciplinarySanctionUnknown,
  };
}
