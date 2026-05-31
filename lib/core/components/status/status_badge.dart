import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Taille du badge de statut.
enum StatusBadgeSize {
  /// Avec padding réduit. Réservée aux listes très denses ou au texte inline.
  small,

  /// Taille standard (défaut).
  medium,
}

/// Badge visuel représentant un statut métier : icône + libellé + couleur sémantique.
///
/// **Constructeur principal** : fournir icon, label, color explicitement.
///
/// **Factories nommées** : chaque domaine métier expose ses propres constructeurs
/// pour éviter à l'appelant de connaître la couleur et l'icône.
/// Le [label] est toujours fourni par l'appelant (résolu via l10n).
///
/// Cas particulier couleur muted : quand [color] == [AppColors.textMuted],
/// le fond passe sur [AppColors.surfaceAlt] et la bordure sur [AppColors.border]
/// pour rester lisible (10 % d'opacité sur gris est trop pâle).
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final StatusBadgeSize size;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.size = StatusBadgeSize.medium,
  });

  // ---------------------------------------------------------------------------
  // Factories — Paiement
  // ---------------------------------------------------------------------------

  factory StatusBadge.paid({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.check_circle,
    label: label,
    color: AppColors.success,
    size: size,
  );

  factory StatusBadge.partial({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.pending,
    label: label,
    color: AppColors.warning,
    size: size,
  );

  factory StatusBadge.overdue({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.error_outline,
    label: label,
    color: AppColors.error,
    size: size,
  );

  factory StatusBadge.cancelled({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cancel,
    label: label,
    color: AppColors.textMuted,
    size: size,
  );

  // ---------------------------------------------------------------------------
  // Factories — Présence / Absence
  // ---------------------------------------------------------------------------

  factory StatusBadge.present({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.check,
    label: label,
    color: AppColors.success,
    size: size,
  );

  factory StatusBadge.absentJustified({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.event_busy,
    label: label,
    color: AppColors.warning,
    size: size,
  );

  factory StatusBadge.absentUnjustified({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.block,
    label: label,
    color: AppColors.error,
    size: size,
  );

  // ---------------------------------------------------------------------------
  // Factories — Synchronisation
  // ---------------------------------------------------------------------------

  factory StatusBadge.synced({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cloud_done,
    label: label,
    color: AppColors.success,
    size: size,
  );

  factory StatusBadge.syncing({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cloud_sync,
    label: label,
    color: AppColors.info,
    size: size,
  );

  factory StatusBadge.offline({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cloud_off,
    label: label,
    color: AppColors.textMuted,
    size: size,
  );

  factory StatusBadge.pendingUpload({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cloud_upload,
    label: label,
    color: AppColors.warning,
    size: size,
  );

  factory StatusBadge.syncConflict({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.sync_problem,
    label: label,
    color: AppColors.error,
    size: size,
  );

  // ---------------------------------------------------------------------------
  // Factories — Inscription (EnrollmentStatus — 9 valeurs)
  // ---------------------------------------------------------------------------

  factory StatusBadge.enrollmentPreRegistered({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.schedule,
    label: label,
    color: AppColors.warning,
    size: size,
  );

  factory StatusBadge.enrollmentInProgress({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.pending_outlined,
    label: label,
    color: AppColors.bleuArdoise,
    size: size,
  );

  factory StatusBadge.enrollmentAdminCompleted({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.task_alt,
    label: label,
    color: AppColors.info,
    size: size,
  );

  factory StatusBadge.enrollmentFinancialCompleted({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.payments,
    label: label,
    color: AppColors.orDoux,
    size: size,
  );

  factory StatusBadge.enrollmentCompleted({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.check_circle_outline,
    label: label,
    color: AppColors.success,
    size: size,
  );

  factory StatusBadge.enrollmentCancelled({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cancel,
    label: label,
    color: AppColors.textMuted,
    size: size,
  );

  factory StatusBadge.enrollmentValidated({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.check_circle,
    label: label,
    color: AppColors.success,
    size: size,
  );

  factory StatusBadge.enrollmentRejected({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.cancel,
    label: label,
    color: AppColors.error,
    size: size,
  );

  factory StatusBadge.enrollmentPending({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) => StatusBadge(
    icon: Icons.hourglass_empty,
    label: label,
    color: AppColors.textMuted,
    size: size,
  );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isNeutral = color == AppColors.textMuted;

    final bgColor = isNeutral
        ? AppColors.surfaceAlt
        : color.withValues(alpha: 0.10);
    final borderColor = isNeutral
        ? AppColors.border
        : color.withValues(alpha: 0.25);

    final double iconSize;
    final double hPadding;
    final double vPadding;

    switch (size) {
      case StatusBadgeSize.small:
        iconSize = 12;
        hPadding = 6;
        vPadding = 2;
      case StatusBadgeSize.medium:
        iconSize = 14;
        hPadding = 8;
        vPadding = 4;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
