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

  /// Couleur de la pastille de statut (cf. spec MÉTIER-7).
  Color getColor() => switch (this) {
    DisciplinaryCaseStatus.open => AppColors.error,
    DisciplinaryCaseStatus.inProgress => AppColors.warning,
    DisciplinaryCaseStatus.closed => AppColors.textSecondary,
    DisciplinaryCaseStatus.unknown => AppColors.muted,
  };

  IconData getIcon() => switch (this) {
    DisciplinaryCaseStatus.open => Icons.error_outline_rounded,
    DisciplinaryCaseStatus.inProgress => Icons.schedule_rounded,
    DisciplinaryCaseStatus.closed => Icons.done_all_rounded,
    DisciplinaryCaseStatus.unknown => Icons.help_outline_rounded,
  };

  /// Statut suivant dans le cycle linéaire (sens unique) ; `null` si terminal.
  DisciplinaryCaseStatus? get nextStatus => switch (this) {
    DisciplinaryCaseStatus.open => DisciplinaryCaseStatus.inProgress,
    DisciplinaryCaseStatus.inProgress => DisciplinaryCaseStatus.closed,
    DisciplinaryCaseStatus.closed || DisciplinaryCaseStatus.unknown => null,
  };

  /// Libellé du bouton qui pousse au statut suivant ; `null` si terminal.
  String? advanceActionLabel(AppLocalizations l10n) => switch (this) {
    DisciplinaryCaseStatus.open => l10n.disciplinaryAdvanceTakeCharge,
    DisciplinaryCaseStatus.inProgress => l10n.disciplinaryAdvanceClose,
    DisciplinaryCaseStatus.closed || DisciplinaryCaseStatus.unknown => null,
  };
}
