import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
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

  /// Les filtres Journalier · Hebdomadaire · Mensuel, à gauche de la même
  /// carte (B1) ; ils passent au-dessus sur téléphone.
  final Widget? filters;

  /// Le sélecteur de date du Journalier. `null` : aucun.
  final VoidCallback? onPickDate;

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
    this.filters,
    this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = capitalizeFirst(this.label ?? l10n.treasuryDayLong(date));
    final today = onToday;
    final filters = this.filters;
    final pick = onPickDate;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.treasuryPanelRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: TreasuryTones.cardShadow,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          ?filters,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
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
              if (pick != null)
                OutlinedButton.icon(
                  onPressed: pick,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    size: AppSpacing.lg - 2,
                  ),
                  label: Text(l10n.treasuryNumericDate(date)),
                  style: _boxStyle(),
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

  // 40 × 40 à l'œil, r11, bordure terre cuite claire ; 48 au doigt.
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: AppColors.treasuryOpeningInk,
      disabledForegroundColor: AppColors.treasuryOpeningInk.withValues(
        alpha: 0.35,
      ),
      fixedSize: const Size.square(AppDimensions.treasuryNavButton),
      minimumSize: const Size.square(AppDimensions.treasuryNavButton),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.treasuryNavRadius),
        side: const BorderSide(color: AppColors.treasuryOpeningBorder),
      ),
    ),
  );
}

ButtonStyle _boxStyle() => OutlinedButton.styleFrom(
  foregroundColor: AppColors.textPrimary,
  minimumSize: const Size(0, AppDimensions.treasuryNavButton),
  tapTargetSize: MaterialTapTargetSize.padded,
  side: const BorderSide(color: AppColors.border),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(
      AppDimensions.treasuryFormatButtonRadius,
    ),
  ),
);

/// « jeudi 22 octobre 2026 » → « Jeudi 22 octobre 2026 » : la première lettre
/// seulement (B1).
String capitalizeFirst(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
