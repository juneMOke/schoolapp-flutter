import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';

/// L'agent d'une ligne du registre : initiales et pastille de synchro,
/// « Nom Post-nom », « Prénom · Fonction », et le badge VAC · H d'un
/// vacataire payé à l'heure. Partagé par la carte et la ligne.
class StaffAgentHeading extends StatelessWidget {
  final StaffDayRow row;

  const StaffAgentHeading({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final member = row.member;
    final job = member.jobTitle;
    return Row(
      children: [
        StaffAvatar(
          member: member,
          sync: row.sync,
          size: AppDimensions.presenceMarkAvatarSize,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StaffAttendanceLabels.familyName(member),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                [member.firstName, ?job].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (row.isHourly) const _HourlyBadge(),
      ],
    );
  }
}

class _HourlyBadge extends StatelessWidget {
  const _HourlyBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: const BoxDecoration(
      color: AppColors.staffVacataireSoft,
      borderRadius: AppRadius.brPill,
    ),
    child: Text(
      AppLocalizations.of(context)!.staffAttendanceHourlyBadge,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.staffVacataireInk,
      ),
    ),
  );
}
