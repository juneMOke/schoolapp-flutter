import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Habillage UI de l'enum offline [DisciplinaryStatus] (cycle réel du contrat :
/// `OPEN → PENDING → RESOLVED`, `DISMISSED` = classement sans suite terminal).
///
/// L'enum reste **pur** côté domaine ; couleurs/icônes/libellés vivent ici.
extension DisciplinaryStatusUi on DisciplinaryStatus {
  String getDisplayName(AppLocalizations l10n) => switch (this) {
    DisciplinaryStatus.open => l10n.disciplinaryCaseStatusOpen,
    DisciplinaryStatus.pending => l10n.disciplinaryStatusOfflinePending,
    DisciplinaryStatus.resolved => l10n.disciplinaryStatusOfflineResolved,
    DisciplinaryStatus.dismissed => l10n.disciplinaryStatusOfflineDismissed,
    DisciplinaryStatus.unknown => l10n.disciplinaryCaseStatusUnknown,
  };

  Color getColor() => switch (this) {
    DisciplinaryStatus.open => AppColors.error,
    DisciplinaryStatus.pending => AppColors.warning,
    DisciplinaryStatus.resolved => AppColors.vertSavane,
    DisciplinaryStatus.dismissed => AppColors.textSecondary,
    DisciplinaryStatus.unknown => AppColors.muted,
  };

  IconData getIcon() => switch (this) {
    DisciplinaryStatus.open => Icons.error_outline_rounded,
    DisciplinaryStatus.pending => Icons.schedule_rounded,
    DisciplinaryStatus.resolved => Icons.done_all_rounded,
    DisciplinaryStatus.dismissed => Icons.block_rounded,
    DisciplinaryStatus.unknown => Icons.help_outline_rounded,
  };

  /// Prochain statut du chemin d'avancement principal
  /// (`OPEN → PENDING → RESOLVED`) ; `null` si terminal.
  DisciplinaryStatus? get advanceTarget => switch (this) {
    DisciplinaryStatus.open => DisciplinaryStatus.pending,
    DisciplinaryStatus.pending => DisciplinaryStatus.resolved,
    _ => null,
  };

  /// Libellé du bouton d'avancement ; `null` si terminal.
  String? advanceActionLabel(AppLocalizations l10n) => switch (this) {
    DisciplinaryStatus.open => l10n.disciplinaryAdvanceTakeCharge,
    DisciplinaryStatus.pending => l10n.disciplinaryAdvanceResolve,
    _ => null,
  };

  /// Un cas non terminal peut être **classé sans suite** (DISMISSED).
  bool get canDismiss =>
      this == DisciplinaryStatus.open || this == DisciplinaryStatus.pending;

  /// Libellé du footer d'un cas terminal ; `null` si non terminal.
  String? terminalLabel(AppLocalizations l10n) => switch (this) {
    DisciplinaryStatus.resolved => l10n.disciplinaryCaseResolvedLabel,
    DisciplinaryStatus.dismissed => l10n.disciplinaryCaseDismissedLabel,
    _ => null,
  };
}
