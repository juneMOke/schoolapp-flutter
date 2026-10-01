import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Les contrôles d'une ligne de registre, partagés par la carte de la grille et
// la ligne de la liste, pour un agent comme pour un élève : une heure, le
// bouton de justification, la reprise d'un envoi refusé.

/// Le détail d'un statut : « +22 min après 07:30 », « Absence justifiée »…
String presenceStatusDetail(
  AppLocalizations l10n,
  PresenceRowView row,
  PresenceSchedule schedule,
) => switch (row.status) {
  PresenceStatus.none => l10n.presenceMarkNotMarked,
  PresenceStatus.present => l10n.presenceMarkOnTime,
  PresenceStatus.late => l10n.presenceMarkLateDetail(
    row.lateMinutes,
    schedule.start.wire,
  ),
  PresenceStatus.absent =>
    row.isJustified
        ? l10n.presenceMarkAbsenceJustified
        : l10n.presenceMarkAbsenceUnjustified,
};

/// Un bouton d'icône carré de 36 dp (effacer, réessayer, ± heure).
class PresenceSquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const PresenceSquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppDimensions.presenceMarkIconButtonSize,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      iconSize: AppSpacing.lg + AppSpacing.xs,
      color: color ?? AppColors.textSecondary,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}

/// Une ligne refusée : son motif, et de quoi la renvoyer. Rien tant que
/// l'envoi n'a pas été refusé.
class PresenceRetryButton extends StatelessWidget {
  final PresenceRowView row;
  final VoidCallback onRetry;

  const PresenceRetryButton({
    super.key,
    required this.row,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final refusal = row.refusal;
    if (refusal == null) return const SizedBox.shrink();
    return PresenceSquareIconButton(
      icon: Icons.refresh,
      color: AppColors.presenceMarkAbsentInk,
      tooltip: '$refusal — ${AppLocalizations.of(context)!.presenceMarkRetry}',
      onPressed: onRetry,
    );
  }
}

/// Une heure (arrivée, départ) : en chiffres quand elle est posée, en pointillé
/// sinon. Toucher ouvre la saisie.
class PresenceTimeButton extends StatelessWidget {
  final String label;
  final ClockTime? time;
  final VoidCallback onTap;

  const PresenceTimeButton({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    return Semantics(
      button: true,
      label: '$label ${time?.wire ?? ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.presenceMarkIconButtonSize,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: time == null ? AppColors.borderStrong : AppColors.border,
            ),
            color: time == null ? null : AppColors.surface,
          ),
          alignment: Alignment.center,
          child: Text(
            time?.wire ?? label,
            style: time == null
                ? AppTypography.labelMedium.copyWith(
                    color: AppColors.textMutedAa,
                  )
                : AppTypography.money.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// « Justifier », ou le motif posé, en vert.
class PresenceJustifyButton extends StatelessWidget {
  final PresenceRowView row;
  final VoidCallback onTap;

  const PresenceJustifyButton({
    super.key,
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = row.justificationLabel;
    final tone = PresenceTone.of(
      label == null ? row.status : PresenceStatus.present,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brPill,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.presenceMarkIconButtonSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: tone.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == null ? Icons.edit_note : Icons.task_alt,
              size: AppSpacing.lg,
              color: tone.ink,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label ?? l10n.presenceMarkJustify,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(color: tone.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
