import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// ‹ septembre 2026 › — partagé par la fiche mensuelle et le récapitulatif ;
/// jamais au-delà du mois en cours. Avec [onPick], le mois ouvre le
/// sélecteur de mois : une icône le dit, et la zone d'appui fait 48 dp.
class PresenceMonthNav extends StatelessWidget {
  /// `YYYY-MM`.
  final String month;
  final bool isCurrent;

  /// `null` : début de l'année scolaire.
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  /// `null` : le mois se lit seulement.
  final VoidCallback? onPick;

  const PresenceMonthNav({
    super.key,
    required this.month,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget arrow(IconData icon, String tooltip, VoidCallback? onPressed) =>
        SizedBox.square(
          dimension: AppDimensions.presenceMarkTapTarget,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon),
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        arrow(Icons.chevron_left, l10n.presenceMarkPreviousMonth, onPrevious),
        _label(context, l10n),
        arrow(
          Icons.chevron_right,
          l10n.presenceMarkNextMonth,
          isCurrent ? null : onNext,
        ),
        if (!isCurrent)
          TextButton(
            onPressed: onCurrent,
            child: Text(l10n.presenceMarkCurrentMonth),
          ),
      ],
    );
  }

  Widget _label(BuildContext context, AppLocalizations l10n) {
    final label = Text(
      PresenceLabels.month(MaterialLocalizations.of(context), month),
      style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
    );
    final onPick = this.onPick;
    if (onPick == null) return label;
    return Tooltip(
      message: l10n.presenceMarkPickMonth,
      child: InkWell(
        onTap: onPick,
        borderRadius: AppRadius.brSm,
        child: TouchTarget(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: label),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.calendar_month_outlined,
                  size: AppSpacing.xl,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
