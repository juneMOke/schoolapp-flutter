import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_rate_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un agent en ligne de « Assiduité par agent » : Agent · Fonction · Présence
/// · Retards · Abs. justifiées · Abs. non justifiées. Une valeur nulle s'écrit
/// « — ».
abstract final class HrPresenceStaffRow {
  /// [onOpen] `null` : la ligne ne s'ouvre pas.
  static DataTableRowSpec of(
    HrAttendanceStaffRow row,
    AppLocalizations l10n, {
    VoidCallback? onOpen,
  }) {
    final agent = row.agent;
    final kpis = row.kpis;
    final name = HrPresenceLabels.fullName(agent);
    String count(int value) => value == 0 ? l10n.hrPresenceNoValue : '$value';
    return DataTableRowSpec(
      id: agent.staffMemberId,
      displayName: name,
      leading: PersonAvatar(
        firstName: agent.firstName ?? '',
        lastName: agent.lastName,
        personId: agent.staffMemberId,
        size: AvatarSize.md,
      ),
      onTap: onOpen,
      trailing: onOpen == null
          ? const DataTableTrailingSpec()
          : DataTableTrailingSpec(
              type: DataTableTrailingType.chevronOpen,
              tooltip: l10n.hrPresenceStaffOpen,
              onTap: onOpen,
            ),
      cells: [
        DataTableCellSpec(text: name, variant: DataTableCellTextVariant.strong),
        DataTableCellSpec(text: agent.jobTitle ?? l10n.hrPresenceNoValue),
        DataTableCellSpec(
          text: '',
          child: _RateCell(pct: kpis.presenceRatePct),
        ),
        DataTableCellSpec(
          text: kpis.late == 0
              ? l10n.hrPresenceNoValue
              : l10n.hrPresenceLateCell(kpis.late, kpis.lateMinutes),
        ),
        DataTableCellSpec(text: count(kpis.justifiedAbsences)),
        DataTableCellSpec(
          text: count(kpis.unjustifiedAbsences),
          variant: kpis.unjustifiedAbsences > 0
              ? DataTableCellTextVariant.strong
              : DataTableCellTextVariant.regular,
          color: kpis.unjustifiedAbsences > 0
              ? AppColors.presenceMarkAbsentInk
              : null,
        ),
      ],
    );
  }
}

/// Mini-barre 40 × 6 et taux, à la teinte du seuil (≥ 95 / 85 / en dessous).
class _RateCell extends StatelessWidget {
  final int? pct;

  const _RateCell({required this.pct});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = this.pct;
    if (pct == null) {
      return Text(
        l10n.hrPresenceNoValue,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
      );
    }
    final tone = PresenceRateTone.of(pct / 100);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimensions.presenceRateMeterHeight / 2),
          ),
          child: SizedBox(
            width: AppDimensions.presenceRateMeterWidth,
            height: AppDimensions.presenceRateMeterHeight,
            child: LinearProgressIndicator(
              value: pct / 100,
              color: tone.color,
              backgroundColor: tone.soft,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.presenceRateValue(pct),
          style: AppTypography.labelMedium.copyWith(
            color: tone.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
