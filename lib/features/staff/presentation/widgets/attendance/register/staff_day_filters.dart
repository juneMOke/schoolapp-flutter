import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Les filtres du registre : puces de statut à compteur, puis la barre
/// partagée (recherche, catégorie, cartes/liste), puis la légende du geste et
/// les incidents à justifier.
class StaffDayFilters extends StatelessWidget {
  final StaffDayRegister register;
  final StaffDayQuery query;
  final CollectionViewMode viewMode;
  final ValueChanged<PresenceStatus?> onStatus;
  final ValueChanged<StaffCategory?> onCategory;
  final ValueChanged<String> onText;
  final ValueChanged<CollectionViewMode> onViewMode;

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
            EteeloFilterChip(
              label: l10n.presenceMarkFilterAll,
              count: register.all.length,
              selected: query.status == null,
              color: AppColors.bleuArdoise,
              soft: AppColors.bleuArdoiseSoft,
              ink: AppColors.bleuArdoise,
              onTap: () => onStatus(null),
            ),
            for (final status in PresenceStatus.values)
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
            // La légende décrit un geste d'écriture : rien à dire sans lui.
            PermissionGate.access(
              kStaffAttendanceWriteAccess,
              child: Text(
                viewMode == CollectionViewMode.grid
                    ? l10n.presenceMarkLegendGrid
                    : l10n.presenceMarkLegendList,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
            ),
            if (register.toJustify > 0)
              Text(
                l10n.presenceMarkToJustify(register.toJustify),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.presenceMarkLateInk,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(AppLocalizations l10n, PresenceStatus status) {
    final tone = PresenceTone.of(status);
    return EteeloFilterChip(
      label: PresenceLabels.filter(l10n, status),
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
