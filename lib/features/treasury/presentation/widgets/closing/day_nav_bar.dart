import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La journée affichée et sa navigation (B1) : ‹ jeudi 22 octobre 2026 ›, et
/// « Aujourd'hui » quand on regarde une autre journée. Les flèches se
/// désactivent aux bornes (début de l'historique, aujourd'hui).
///
/// Sert aussi la semaine et le mois (B7) : [label] remplace la date,
/// [currentHint] la mention « aujourd'hui », [goCurrentLabel] le bouton.
class DayNavBar extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final String? label;
  final String? currentHint;
  final String? goCurrentLabel;
  final bool periodTooltips;

  const DayNavBar({
    super.key,
    required this.date,
    required this.isToday,
    this.onPrevious,
    this.onNext,
    this.onToday,
    this.label,
    this.currentHint,
    this.goCurrentLabel,
    this.periodTooltips = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = capitalizeFirst(this.label ?? l10n.treasuryDayLong(date));
    final today = onToday;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          // La date et ses flèches cèdent la largeur : sur téléphone, la date
          // passe sur deux lignes plutôt que de déborder.
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.treasuryDayNavMaxWidth,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Arrow(
                  icon: Icons.chevron_left,
                  tooltip: periodTooltips
                      ? l10n.treasuryPrevPeriod
                      : l10n.treasuryPrevDay,
                  onPressed: onPrevious,
                ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleSmall,
                      ),
                      if (isToday)
                        Text(
                          currentHint ?? l10n.treasuryTodayLower,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _Arrow(
                  icon: Icons.chevron_right,
                  tooltip: periodTooltips
                      ? l10n.treasuryNextPeriod
                      : l10n.treasuryNextDay,
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          if (!isToday && today != null)
            EteeloButton.ghost(
              label: goCurrentLabel ?? l10n.treasuryToday,
              icon: Icons.today_outlined,
              onPressed: today,
              fullWidth: false,
            ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _Arrow({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: tooltip,
    color: AppColors.terreCuite,
    constraints: const BoxConstraints(
      minWidth: AppDimensions.minTouchTarget,
      minHeight: AppDimensions.minTouchTarget,
    ),
    onPressed: onPressed,
  );
}

/// « jeudi 22 octobre 2026 » → « Jeudi 22 octobre 2026 » : la première lettre
/// seulement (B1).
String capitalizeFirst(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
