import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les puces de contrat — gardées ici, la paie diffère par contrat — et la
/// recherche.
class HrPresenceRecapFilters extends StatelessWidget {
  final int total;
  final Map<StaffContractFilter, int> counts;
  final StaffContractFilter? selected;
  final ValueChanged<StaffContractFilter?> onContract;
  final String text;
  final ValueChanged<String> onText;

  const HrPresenceRecapFilters({
    super.key,
    required this.total,
    required this.counts,
    required this.selected,
    required this.onContract,
    required this.text,
    required this.onText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            EteeloFilterChip(
              label: l10n.presenceMarkFilterAll,
              count: total,
              selected: selected == null,
              color: AppColors.bleuArdoise,
              soft: AppColors.bleuArdoiseSoft,
              ink: AppColors.bleuArdoise,
              onTap: () => onContract(null),
            ),
            for (final filter in StaffContractFilter.values)
              if ((counts[filter] ?? 0) > 0 || selected == filter)
                EteeloFilterChip(
                  label: StaffLabels.contractFilter(l10n, filter),
                  count: counts[filter] ?? 0,
                  selected: selected == filter,
                  color: StaffContractTone.ofFilter(filter).color,
                  soft: StaffContractTone.ofFilter(filter).soft,
                  ink: StaffContractTone.ofFilter(filter).ink,
                  icon: StaffContractTone.ofFilter(filter).icon,
                  onTap: () => onContract(filter),
                ),
          ],
        ),
        StaffSearchToolbar(
          text: text,
          label: l10n.staffAttendanceSearchLabel,
          placeholder: l10n.staffAttendanceSearchPlaceholder,
          onTextChanged: onText,
        ),
      ],
    );
  }
}
