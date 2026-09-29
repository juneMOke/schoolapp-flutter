import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filter_chip.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les filtres du registre : puces de statut à compteur, puis la barre
/// partagée (recherche, catégorie, cartes/liste), puis la légende du geste et
/// les incidents à justifier.
class StaffDayFilters extends StatelessWidget {
  final StaffDayRegister register;
  final StaffDayQuery query;
  final StaffViewMode viewMode;
  final ValueChanged<StaffAttendanceStatus?> onStatus;
  final ValueChanged<StaffCategory?> onCategory;
  final ValueChanged<String> onText;
  final ValueChanged<StaffViewMode> onViewMode;

  const StaffDayFilters({
    super.key,
    required this.register,
    required this.query,
    required this.viewMode,
    required this.onStatus,
    required this.onCategory,
    required this.onText,
    required this.onViewMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StaffFilterChip(
              label: l10n.staffAttendanceFilterAll,
              count: register.all.length,
              selected: query.status == null,
              color: AppColors.bleuArdoise,
              soft: AppColors.bleuArdoiseSoft,
              ink: AppColors.bleuArdoise,
              onTap: () => onStatus(null),
            ),
            for (final status in StaffAttendanceStatus.values)
              _statusChip(l10n, status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        StaffSearchToolbar(
          text: query.text,
          label: l10n.staffAttendanceSearchLabel,
          placeholder: l10n.staffAttendanceSearchPlaceholder,
          onTextChanged: onText,
          category: query.category,
          onCategoryChanged: onCategory,
          viewMode: viewMode,
          onViewModeChanged: onViewMode,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.md,
          children: [
            Text(
              viewMode == StaffViewMode.grid
                  ? l10n.staffAttendanceLegendGrid
                  : l10n.staffAttendanceLegendList,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
            if (register.toJustify > 0)
              Text(
                l10n.staffAttendanceToJustify(register.toJustify),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.staffAttendanceLateInk,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(AppLocalizations l10n, StaffAttendanceStatus status) {
    final tone = StaffAttendanceTone.of(status);
    return StaffFilterChip(
      label: StaffAttendanceLabels.filter(l10n, status),
      count: register.count(status),
      selected: query.status == status,
      color: tone.color,
      soft: tone.soft,
      ink: tone.ink,
      icon: tone.icon,
      onTap: () => onStatus(query.status == status ? null : status),
    );
  }
}
