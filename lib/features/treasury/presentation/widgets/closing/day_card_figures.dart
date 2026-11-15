import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois cases chiffrées d'une carte du jour : Ouverture (fixe), Entrées
/// et Sorties (chacune ouvre sa liste). Le signe dit le sens, la couleur ne le
/// dit jamais seule.
class DayCardFigures extends StatelessWidget {
  final CashDaySummary summary;
  final MovementDirection? open;
  final ValueChanged<MovementDirection> onToggle;

  const DayCardFigures({
    super.key,
    required this.summary,
    required this.open,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = summary.register.currency;
    final figures = [
      _Figure(
        label: l10n.treasuryOpening,
        icon: Icons.calendar_today_outlined,
        value: TreasuryFormat.money(summary.openingInCents, currency),
        ink: AppColors.terreCuite,
      ),
      _Figure(
        label: l10n.treasuryInflows,
        icon: Icons.download,
        count: summary.inflowsCount,
        value: TreasuryFormat.signedMoney(summary.inflowsInCents, currency),
        ink: AppColors.success,
        expanded: open == MovementDirection.inflow,
        onTap: () => onToggle(MovementDirection.inflow),
      ),
      _Figure(
        label: l10n.treasuryOutflows,
        icon: Icons.upload,
        count: summary.outflowsCount,
        value: TreasuryFormat.signedMoney(-summary.outflowsInCents, currency),
        ink: AppColors.error,
        expanded: open == MovementDirection.outflow,
        onTap: () => onToggle(MovementDirection.outflow),
      ),
    ];
    // Autant de cases par rangée que la largeur en tient (3 au plus), à parts
    // égales : un `Wrap` seul les empilerait, chaque case prenant toute la
    // largeur que lui laisse sa rangée.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final perRow =
            ((constraints.maxWidth + gap) /
                    (AppDimensions.treasuryFigureMinWidth + gap))
                .floor()
                .clamp(1, figures.length);
        // Arrondi vers le bas : un reste flottant renverrait la dernière case
        // à la ligne.
        final width = ((constraints.maxWidth - gap * (perRow - 1)) / perRow)
            .floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final figure in figures) SizedBox(width: width, child: figure),
          ],
        );
      },
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final Color ink;
  final int? count;
  final bool expanded;
  final VoidCallback? onTap;

  const _Figure({
    required this.label,
    required this.icon,
    required this.value,
    required this.ink,
    this.count,
    this.expanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tap = onTap;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.md, color: ink),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelCaps.copyWith(color: ink),
                ),
              ),
              if (count != null) Text('$count', style: AppTextStyles.codeMuted),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              softWrap: false,
              style: AppTextStyles.moneyTabular.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          if (tap != null)
            Row(
              children: [
                Flexible(
                  child: Text(
                    expanded ? l10n.treasuryHideDetail : l10n.treasurySeeDetail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: AppSpacing.lg,
                  color: ink,
                ),
              ],
            ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.treasuryFigureMinWidth,
        minHeight: AppDimensions.minTouchTarget,
      ),
      child: Semantics(
        button: tap != null,
        expanded: tap == null ? null : expanded,
        child: Material(
          color: ink.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brMd,
            side: BorderSide(
              color: expanded ? ink : ink.withValues(alpha: 0.2),
              width: expanded ? 2 : 1,
            ),
          ),
          child: tap == null
              ? content
              : InkWell(
                  borderRadius: AppRadius.brMd,
                  onTap: tap,
                  child: content,
                ),
        ),
      ),
    );
  }
}
