import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Taille du badge de statut.
enum StatusBadgeSize {
  /// Avec padding réduit. Réservée aux listes très denses ou au texte inline.
  small,

  /// Taille standard (défaut).
  medium,
}

/// Variante visuelle du badge.
enum StatusBadgeStyle {
  /// Fond léger teinté + bordure discrète (rétro-compatible).
  soft,

  /// Fond plein adaptatif avec texte contrasté si AA est respecté.
  filled,
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
  final StatusBadgeStyle style;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.size = StatusBadgeSize.medium,
    this.style = StatusBadgeStyle.soft,
  });

  // ---------------------------------------------------------------------------
  // Factories — Paiement
  // ---------------------------------------------------------------------------

  factory StatusBadge.paid({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.check_circle,
    label: label,
    color: AppColors.success,
    size: size,
    style: style,
  );

  factory StatusBadge.partial({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.pending,
    label: label,
    color: AppColors.warning,
    size: size,
    style: style,
  );

  factory StatusBadge.overdue({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.error_outline,
    label: label,
    color: AppColors.error,
    size: size,
    style: style,
  );

  factory StatusBadge.cancelled({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cancel,
    label: label,
    color: AppColors.textMuted,
    size: size,
    style: style,
  );

  // ---------------------------------------------------------------------------
  // Factories — Présence / Absence
  // ---------------------------------------------------------------------------

  factory StatusBadge.present({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.check,
    label: label,
    color: AppColors.success,
    size: size,
    style: style,
  );

  factory StatusBadge.absentJustified({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.event_busy,
    label: label,
    color: AppColors.warning,
    size: size,
    style: style,
  );

  factory StatusBadge.absentUnjustified({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.block,
    label: label,
    color: AppColors.error,
    size: size,
    style: style,
  );

  // ---------------------------------------------------------------------------
  // Factories — Synchronisation
  // ---------------------------------------------------------------------------

  factory StatusBadge.synced({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cloud_done,
    label: label,
    color: AppColors.success,
    size: size,
    style: style,
  );

  factory StatusBadge.syncing({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cloud_sync,
    label: label,
    color: AppColors.info,
    size: size,
    style: style,
  );

  factory StatusBadge.offline({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cloud_off,
    label: label,
    color: AppColors.textMuted,
    size: size,
    style: style,
  );

  factory StatusBadge.pendingUpload({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cloud_upload,
    label: label,
    color: AppColors.warning,
    size: size,
    style: style,
  );

  factory StatusBadge.syncConflict({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.sync_problem,
    label: label,
    color: AppColors.error,
    size: size,
    style: style,
  );

  // ---------------------------------------------------------------------------
  // Factories — Inscription (EnrollmentStatus — 9 valeurs)
  // ---------------------------------------------------------------------------

  factory StatusBadge.enrollmentPreRegistered({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.schedule,
    label: label,
    color: AppColors.warning,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentInProgress({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.pending_outlined,
    label: label,
    color: AppColors.bleuArdoise,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentAdminCompleted({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.task_alt,
    label: label,
    color: AppColors.info,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentFinancialCompleted({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.payments,
    label: label,
    color: AppColors.orDoux,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentCompleted({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.check_circle_outline,
    label: label,
    color: AppColors.success,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentCancelled({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cancel,
    label: label,
    color: AppColors.textMuted,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentValidated({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.check_circle,
    label: label,
    color: AppColors.success,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentRejected({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.cancel,
    label: label,
    color: AppColors.error,
    size: size,
    style: style,
  );

  factory StatusBadge.enrollmentPending({
    required String label,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeStyle style = StatusBadgeStyle.soft,
  }) => StatusBadge(
    icon: Icons.hourglass_empty,
    label: label,
    color: AppColors.textMuted,
    size: size,
    style: style,
  );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final config = _resolveVisualConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.horizontalPadding,
        vertical: config.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: config.borderRadius,
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: config.iconSize, color: config.foregroundColor),
          const SizedBox(width: AppSpacing.sm),
          // Flexible + ellipsis : la pastille reste compacte mais se rétracte
          // proprement quand l'espace est contraint (ex. carte grille étroite).
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: config.foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusBadgeVisualConfig _resolveVisualConfig() {
    return switch (style) {
      StatusBadgeStyle.soft => _resolveSoftVisualConfig(),
      StatusBadgeStyle.filled => _resolveFilledVisualConfig(),
    };
  }

  _StatusBadgeVisualConfig _resolveSoftVisualConfig() {
    final isNeutral = color == AppColors.textMuted;

    final backgroundColor = isNeutral
        ? AppColors.surfaceAlt
        : color.withValues(alpha: 0.10);
    final borderColor = isNeutral
        ? AppColors.border
        : color.withValues(alpha: 0.25);

    final double iconSize;
    final double horizontalPadding;
    final double verticalPadding;

    switch (size) {
      case StatusBadgeSize.small:
        iconSize = AppDimensions.chipIconSize;
        horizontalPadding = 6;
        verticalPadding = 2;
      case StatusBadgeSize.medium:
        iconSize = 14;
        horizontalPadding = AppSpacing.sm;
        verticalPadding = AppDimensions.chipPaddingV;
    }

    return _StatusBadgeVisualConfig(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      foregroundColor: color,
      borderRadius: AppRadius.brSm,
      iconSize: iconSize,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
    );
  }

  _StatusBadgeVisualConfig _resolveFilledVisualConfig() {
    final adaptiveForeground = _bestAdaptiveForeground(color);
    final bestContrast = adaptiveForeground == null
        ? 0.0
        : _contrastRatio(color, adaptiveForeground);

    if (adaptiveForeground == null || bestContrast < 4.5) {
      return const _StatusBadgeVisualConfig(
        backgroundColor: AppColors.surfaceAlt,
        borderColor: AppColors.border,
        foregroundColor: AppColors.textPrimary,
        borderRadius: AppRadius.brPill,
        iconSize: AppDimensions.chipIconSize,
        horizontalPadding: AppDimensions.chipPaddingH,
        verticalPadding: AppDimensions.chipPaddingV,
      );
    }

    return _StatusBadgeVisualConfig(
      backgroundColor: color,
      borderColor: color,
      foregroundColor: adaptiveForeground,
      borderRadius: AppRadius.brPill,
      iconSize: AppDimensions.chipIconSize,
      horizontalPadding: AppDimensions.chipPaddingH,
      verticalPadding: AppDimensions.chipPaddingV,
    );
  }

  Color? _bestAdaptiveForeground(Color background) {
    final offWhiteContrast = _contrastRatio(background, AppColors.blancCasse);
    final warmBlackContrast = _contrastRatio(background, AppColors.noirChaud);

    return offWhiteContrast >= warmBlackContrast
        ? AppColors.blancCasse
        : AppColors.noirChaud;
  }

  double _contrastRatio(Color a, Color b) {
    final luminanceA = a.computeLuminance();
    final luminanceB = b.computeLuminance();
    final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
    final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

class _StatusBadgeVisualConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final BorderRadius borderRadius;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _StatusBadgeVisualConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.borderRadius,
    required this.iconSize,
    required this.horizontalPadding,
    required this.verticalPadding,
  });
}
