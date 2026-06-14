import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinarySeverity { minor, major, serious, unknown }

extension DisciplinarySeverityX on DisciplinarySeverity {
  static DisciplinarySeverity fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'MINOR' => DisciplinarySeverity.minor,
        'MAJOR' => DisciplinarySeverity.major,
        'SERIOUS' => DisciplinarySeverity.serious,
        _ => DisciplinarySeverity.unknown,
      };

  String toApiValue() => switch (this) {
    DisciplinarySeverity.minor => 'MINOR',
    DisciplinarySeverity.major => 'MAJOR',
    DisciplinarySeverity.serious => 'SERIOUS',
    DisciplinarySeverity.unknown => 'UNKNOWN',
  };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
    DisciplinarySeverity.minor => l10n.disciplinarySeverityMinor,
    DisciplinarySeverity.major => l10n.disciplinarySeverityMajor,
    DisciplinarySeverity.serious => l10n.disciplinarySeveritySerious,
    DisciplinarySeverity.unknown => l10n.disciplinarySeverityUnknown,
  };

  /// Couleur du liséré et du chip de gravité (cf. spec MÉTIER-8).
  Color getColor() => switch (this) {
    DisciplinarySeverity.minor => AppColors.bleuArdoise,
    DisciplinarySeverity.major => AppColors.warning,
    DisciplinarySeverity.serious => AppColors.error,
    DisciplinarySeverity.unknown => AppColors.textMuted,
  };
}
