import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La légende des cellules, et ce que fait Entrée. Les pastilles reprennent les
/// styles de la grille ; l'aide clavier s'efface sur téléphone.
class CoteBulletinLegend extends StatelessWidget {
  final List<CoteColumn> columns;
  final CoteMove enterMove;
  final bool showKeyboardHelp;
  final VoidCallback onToggleEnter;

  const CoteBulletinLegend({
    super.key,
    required this.columns,
    required this.enterMove,
    required this.showKeyboardHelp,
    required this.onToggleEnter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.blancCasse,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Item(
            swatch: const _DashedSwatch(
              surface: AppColors.coteEmptySurface,
              border: AppColors.coteEmptyBorder,
            ),
            label: l10n.coteLegendEmpty,
          ),
          _Item(
            swatch: const _Swatch(
              surface: AppColors.surfaceRaised,
              border: AppColors.coteCellBorder,
            ),
            label: l10n.coteLegendPeriod,
          ),
          if (columns.any((c) => c.isExamen))
            _Item(
              swatch: const _Swatch(
                surface: AppColors.coteExamSurface,
                border: AppColors.coteExamBorder,
              ),
              label: l10n.coteLegendExam,
            ),
          _Item(
            swatch: const _DashedSwatch(
              surface: AppColors.surfaceRaised,
              border: AppColors.coteCellBorder,
            ),
            label: l10n.coteLegendCalculated,
          ),
          if (columns.any((c) => !c.isInput))
            _Item(
              swatch: const _Swatch(
                surface: AppColors.bleuArdoiseSoft,
                border: AppColors.bleuArdoiseSoft,
              ),
              label: l10n.coteLegendTotal,
            ),
          _Item(
            swatch: const _Dot(AppColors.error),
            label: l10n.coteLegendBelowHalf,
          ),
          _Item(
            swatch: const _Dot(AppColors.vertSavane),
            label: l10n.coteLegendHalfOrMore,
          ),
          if (showKeyboardHelp)
            Tooltip(
              message: l10n.coteLegendEnterToggle,
              child: TextButton(
                onPressed: onToggleEnter,
                child: Text(
                  '${l10n.coteLegendEnterKey} → '
                  '${enterMove == CoteMove.down ? l10n.coteLegendEnterDown : l10n.coteLegendEnterRight}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Widget swatch;
  final String label;

  const _Item({required this.swatch, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.coteLegendSwatch,
      height: AppDimensions.coteLegendSwatch,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color surface;
  final Color border;

  const _Swatch({required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.coteLegendSwatch,
      height: AppDimensions.coteLegendSwatch,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDimensions.coteSwatchRadius),
        ),
        border: Border.all(color: border),
      ),
    );
  }
}

class _DashedSwatch extends StatelessWidget {
  final Color surface;
  final Color border;

  const _DashedSwatch({required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppDimensions.coteLegendSwatch,
      child: CustomPaint(
        painter: DashedRRectPainter(
          color: border,
          borderRadius: AppRadius.brSm,
          strokeWidth: 1,
          dash: 3,
          gap: 2,
        ),
        child: ColoredBox(color: surface.withValues(alpha: 0.6)),
      ),
    );
  }
}
