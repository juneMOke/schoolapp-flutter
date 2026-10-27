import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le sort des non-pointés, choisi explicitement avant de valider : les
/// laisser « à pointer », ou les marquer présents. Rien n'est choisi
/// d'avance ([value] `null`) : marquer présent n'est jamais un réflexe.
class PresenceUnmarkedChoice extends StatelessWidget {
  /// `true` : les marquer présents ; `false` : les laisser ; `null` : rien.
  final bool? value;
  final ValueChanged<bool> onChanged;

  const PresenceUnmarkedChoice({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = switch (value) {
      null => l10n.presenceMarkUnmarkedChoiceHint,
      false => l10n.presenceMarkReportUnmarkedReminder,
      true => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.presenceMarkUnmarkedChoiceLabel,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedTabFilter<bool?>(
          semanticsLabel: l10n.presenceMarkUnmarkedChoiceLabel,
          selected: value,
          expand: true,
          onSelected: (choice) {
            if (choice != null) onChanged(choice);
          },
          options: [
            SegmentedTabOption(
              label: l10n.presenceMarkUnmarkedKeep,
              value: false,
              icon: Icons.pending_outlined,
            ),
            SegmentedTabOption(
              label: l10n.presenceMarkUnmarkedMarkPresent,
              value: true,
              icon: Icons.how_to_reg_outlined,
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            note,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        ],
      ],
    );
  }
}
