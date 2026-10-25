import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Mensuelle (défaut, avec sa navigation de mois) ou Annuelle (« Année
/// scolaire 2026-2027 · au … ») : la même bascule dans la liste et dans la
/// fiche, et la portée suit l'utilisateur de l'une à l'autre.
class HrPresenceScopeBar extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onYearly;
  final String month;
  final bool isCurrentMonth;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  /// « Année scolaire 2026-2027 · au 23 oct. 2026 » ; `null` tant que la
  /// réponse n'est pas là.
  final String? yearLabel;

  const HrPresenceScopeBar({
    super.key,
    required this.yearly,
    required this.onYearly,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    this.yearLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = yearLabel;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedTabFilter<bool>(
          semanticsLabel: l10n.hrPresenceScopeA11y,
          selected: yearly,
          onSelected: onYearly,
          options: [
            SegmentedTabOption(
              label: l10n.hrPresenceScopeMonthly,
              value: false,
              icon: Icons.calendar_view_month_outlined,
            ),
            SegmentedTabOption(
              label: l10n.hrPresenceScopeYearly,
              value: true,
              icon: Icons.date_range_outlined,
            ),
          ],
        ),
        if (!yearly)
          PresenceMonthNav(
            month: month,
            isCurrent: isCurrentMonth,
            onPrevious: onPrevious,
            onNext: onNext,
            onCurrent: onCurrent,
          )
        else if (label != null)
          Text(
            label,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}
