import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le titre d'une section de la liste (« À VENIR 1 », « ARCHIVES 2 ») : le
/// libellé en capitales, le compteur, et à droite un geste facultatif.
class CalendarsSectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Widget? trailing;

  const CalendarsSectionTitle({
    super.key,
    required this.title,
    required this.count,
    this.trailing,
  });

  Widget _label() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          title.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + AppSpacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$count',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
    child: Row(
      children: [
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: _label()),
        ),
        ?trailing,
      ],
    ),
  );
}

/// La grille des cartes : autant de colonnes de 280 dp au moins que la
/// largeur en tient (maquette `repeat(auto-fill, minmax(280px, 1fr))`).
class CalendarsGrid extends StatelessWidget {
  final List<Widget> children;

  const CalendarsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpacing.md;
      final columns =
          ((constraints.maxWidth + gap) /
                  (AppDimensions.calendarCardMinWidth + gap))
              .floor()
              .clamp(1, 1 << 10);
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// « Afficher ⌄ » / « Masquer ⌃ » au bout du titre des archives.
class CalendarsSectionToggle extends StatelessWidget {
  final bool expanded;
  final String showLabel;
  final String hideLabel;
  final VoidCallback onPressed;

  const CalendarsSectionToggle({
    super.key,
    required this.expanded,
    required this.showLabel,
    required this.hideLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    iconAlignment: IconAlignment.end,
    icon: Icon(
      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
      size: AppDimensions.detailMiniIconSize,
    ),
    label: Text(expanded ? hideLabel : showLabel),
    style: TextButton.styleFrom(
      foregroundColor: AppColors.bleuArdoise,
      minimumSize: const Size(0, AppDimensions.minTouchTarget),
      textStyle: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
