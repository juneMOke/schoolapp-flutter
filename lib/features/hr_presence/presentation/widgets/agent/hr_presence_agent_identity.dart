import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_rate_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte d'identité du détail : avatar, nom, « fonction · contrat ·
/// matricule », et à droite la présence du mois à la couleur de son seuil.
class HrPresenceAgentIdentity extends StatelessWidget {
  final HrAttendanceAgent agent;

  /// `null` : rien de pointé sur le mois — « — ».
  final int? presenceRatePct;

  const HrPresenceAgentIdentity({
    super.key,
    required this.agent,
    required this.presenceRatePct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = presenceRatePct;
    final tone = pct == null ? null : PresenceRateTone.of(pct / 100);
    final detail = [
      agent.jobTitle,
      if (agent.contractKind != null)
        StaffLabels.contract(l10n, agent.contractKind),
      agent.staffNumber,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' · ');
    return EteeloPanelCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonAvatar(
                firstName: agent.firstName ?? '',
                lastName: agent.lastName,
                personId: agent.staffMemberId,
                size: AvatarSize.lg,
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HrPresenceLabels.fullName(agent),
                      style: AppTypography.titleLarge.copyWith(
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
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.hrPresenceAgentMonthRate,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                pct == null
                    ? l10n.hrPresenceNoValue
                    : l10n.presenceRateValue(pct),
                style: AppTypography.headlineMedium.copyWith(
                  color: tone?.ink ?? AppColors.textMutedAa,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
