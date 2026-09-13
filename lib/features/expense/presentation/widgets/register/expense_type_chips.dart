import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Filtre par type (spec §3) : plusieurs puces possibles, **aucune = tous**.
///
/// Le compteur d'une puce dit ce qu'elle apporterait sur la période, pas ce
/// qu'il resterait après recoupement ; les types à zéro restent visibles et
/// cliquables — leur absence est une information.
class ExpenseTypeChips extends StatelessWidget {
  final List<ExpenseType> types;
  final Set<String> selected;
  final Map<String, int> counts;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  const ExpenseTypeChips({
    super.key,
    required this.types,
    required this.selected,
    required this.counts,
    required this.onToggle,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.expenseTypesTitle.toUpperCase(),
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(width: AppDimensions.spacingS),
              TextButton(
                onPressed: onClear,
                child: Text(l10n.expenseTypesShowAll),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            for (final type in types)
              _TypeChip(
                type: type,
                selected: selected.contains(type.id),
                count: counts[type.id] ?? 0,
                onTap: () => onToggle(type.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ExpenseType type;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ExpenseTypeColors.of(type);
    final foreground = selected ? colors.color : AppColors.textSecondary;
    final radius = BorderRadius.circular(AppDimensions.expenseChipRadius);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.expenseTypeChipA11y(type.shortLabel, count),
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.soft : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? colors.color : AppColors.border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.expenseChipHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingS + AppDimensions.spacingXS,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ExpenseTypeVisuals.icon(type.icon),
                    size: AppDimensions.expenseChipIconSize,
                    color: foreground,
                  ),
                  const SizedBox(width: AppDimensions.expenseInlineGap),
                  Text(
                    type.shortLabel,
                    style:
                        (selected
                                ? AppTextStyles.bodyStrong
                                : AppTextStyles.caption)
                            .copyWith(color: foreground),
                  ),
                  const SizedBox(width: AppDimensions.expenseInlineGap),
                  Text(
                    '$count',
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? colors.color : AppColors.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
