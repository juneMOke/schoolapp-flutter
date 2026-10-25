import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';

import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_profile_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_profile_badge.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_share_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un agent de la fiche individuelle : liseré et anneau d'avatar à la
/// couleur de son profil, « fonction · catégorie », la barre tricolore et ses
/// trois taux, le badge du profil. Toute la ligne ouvre sa fiche.
class HrPresenceProfileRow extends StatelessWidget {
  final HrAttendanceProfileRow row;
  final VoidCallback onOpen;

  const HrPresenceProfileRow({
    super.key,
    required this.row,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceProfileTone.of(row.profile);
    final agent = row.agent;
    final name = HrPresenceLabels.fullName(agent);
    final detail = [
      agent.jobTitle,
      if (agent.category != null) StaffLabels.category(l10n, agent.category!),
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' · ');
    final presence = row.presenceRatePct;
    final late = row.lateRatePct ?? 0;
    final absent = row.absenceRatePct ?? 0;
    String rate(int? pct) =>
        pct == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(pct);
    final rates = l10n.hrPresenceProfileRates(
      rate(presence),
      rate(row.lateRatePct),
      rate(row.absenceRatePct),
    );
    final share = SizedBox(
      width: AppDimensions.presenceShareBarWidth,
      child: PresenceShareBar(
        onTimePct: presence == null ? 0 : (presence - late).clamp(0, 100),
        latePct: late,
        absentPct: absent,
      ),
    );
    final identity = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.presenceProfileRingWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: tone.color,
              width: AppDimensions.presenceProfileRingWidth,
            ),
          ),
          child: PersonAvatar(
            firstName: agent.firstName ?? '',
            lastName: agent.lastName,
            personId: agent.staffMemberId,
            size: AvatarSize.md,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final figures = Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        share,
        Text(
          rates,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        PresenceProfileBadge(profile: row.profile),
      ],
    );
    return Material(
      color: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: tone.color,
                width: AppDimensions.presenceProfileAccentWidth,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inline =
                    constraints.maxWidth >=
                    AppDimensions.presenceProfileRowInlineMinWidth;
                // L'œil des tables de l'app : toute la ligne ouvre aussi.
                final eye = DataTableTrailingRegistry.build(
                  context,
                  DataTableTrailingSpec(
                    type: DataTableTrailingType.eye,
                    tooltip: l10n.hrPresenceStaffOpen,
                    onTap: onOpen,
                  ),
                );
                if (inline) {
                  return Row(
                    children: [
                      Expanded(flex: 5, child: identity),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 6, child: figures),
                      eye,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          identity,
                          const SizedBox(height: AppSpacing.sm),
                          figures,
                        ],
                      ),
                    ),
                    eye,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
