import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinaryCaseStatus { open, inProgress, closed, unknown }

extension DisciplinaryCaseStatusX on DisciplinaryCaseStatus {
  static DisciplinaryCaseStatus fromApiValue(String value) =>
      switch (value.toUpperCase()) {
        'OPEN' => DisciplinaryCaseStatus.open,
        'IN_PROGRESS' ||
        'INPROGRESS' ||
        'IN-PROGRESS' => DisciplinaryCaseStatus.inProgress,
        'CLOSED' || 'CLOSE' || 'DONE' => DisciplinaryCaseStatus.closed,
        _ => DisciplinaryCaseStatus.unknown,
      };

  String toApiValue() => switch (this) {
    DisciplinaryCaseStatus.open => 'OPEN',
    DisciplinaryCaseStatus.inProgress => 'IN_PROGRESS',
    DisciplinaryCaseStatus.closed => 'CLOSED',
    DisciplinaryCaseStatus.unknown => 'UNKNOWN',
  };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
    DisciplinaryCaseStatus.open => l10n.disciplinaryCaseStatusOpen,
    DisciplinaryCaseStatus.inProgress => l10n.disciplinaryCaseStatusInProgress,
    DisciplinaryCaseStatus.closed => l10n.disciplinaryCaseStatusClosed,
    DisciplinaryCaseStatus.unknown => l10n.disciplinaryCaseStatusUnknown,
  };

  Color getColor() => switch (this) {
    DisciplinaryCaseStatus.open => AppColors.bleuArdoise,
    DisciplinaryCaseStatus.inProgress => AppColors.warning,
    DisciplinaryCaseStatus.closed => AppColors.success,
    DisciplinaryCaseStatus.unknown => AppColors.muted,
  };
}
