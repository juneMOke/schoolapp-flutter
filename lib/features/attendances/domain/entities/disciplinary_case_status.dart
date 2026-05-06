import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinaryCaseStatus { open, unknown }

extension DisciplinaryCaseStatusX on DisciplinaryCaseStatus {
  static DisciplinaryCaseStatus fromApiValue(String value) =>
      switch (value.toUpperCase()) {
        'OPEN' => DisciplinaryCaseStatus.open,
        _ => DisciplinaryCaseStatus.unknown,
      };

  String toApiValue() => switch (this) {
    DisciplinaryCaseStatus.open => 'OPEN',
    DisciplinaryCaseStatus.unknown => 'UNKNOWN',
  };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
    DisciplinaryCaseStatus.open => l10n.disciplinaryCaseStatusOpen,
    DisciplinaryCaseStatus.unknown => l10n.disciplinaryCaseStatusUnknown,
  };

  Color getColor() => switch (this) {
    DisciplinaryCaseStatus.open => AppColors.warning,
    DisciplinaryCaseStatus.unknown => AppColors.muted,
  };
}
