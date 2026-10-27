import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_profile_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_profile_badge.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête de la fiche : l'agent sur le voile de son profil — liseré,
/// anneau d'avatar et bord à sa teinte —, et à droite « Profil · {portée} »,
/// le badge et sa règle en clair.
class HrPresenceProfileCard extends StatelessWidget {
  final HrAttendanceAgent agent;
  final PresenceProfile profile;

  /// « octobre 2026 », ou « année 2026-2027 ».
  final String scopeLabel;

  /// La règle avec les chiffres de l'agent ; `null` : la règle seule.
  final String? evidence;

  /// « 21 jours pointés sur 23 jours de classe » ; `null` : rien.
  final String? coverage;

  /// En tête d'une feuille ([HrPresenceFicheSheet]) : sans bord ni coins
  /// propres, la feuille les porte.
  final bool embedded;

  const HrPresenceProfileCard({
    super.key,
    required this.agent,
    required this.profile,
    required this.scopeLabel,
    this.evidence,
    this.coverage,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceProfileTone.of(profile);
    final evidence = this.evidence;
    final coverage = this.coverage;
    final detail = [
      agent.jobTitle,
      if (agent.category != null) StaffLabels.category(l10n, agent.category!),
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' · ');
    return Container(
      decoration: BoxDecoration(
        borderRadius: embedded ? null : AppRadius.brLg,
        border: embedded ? null : Border.all(color: tone.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.soft, AppColors.surfaceRaised],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: tone.color,
              width: AppDimensions.presenceProfileHeaderAccentWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      AppDimensions.presenceProfileRingWidth,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tone.color,
                        width: AppDimensions.presenceProfileHeaderRingWidth,
                      ),
                    ),
                    child: PersonAvatar(
                      firstName: agent.firstName ?? '',
                      lastName: agent.lastName,
                      personId: agent.staffMemberId,
                      size: AvatarSize.lg,
                    ),
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
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (agent.contractKind != null)
                              StaffContractBadge(kind: agent.contractKind),
                            if (detail.isNotEmpty)
                              Text(
                                detail,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.hrPresenceProfileRuleMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.hrPresenceProfileOf(scopeLabel),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PresenceProfileBadge(profile: profile, large: true),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      PresenceLabels.profileRule(l10n, profile),
                      style: AppTypography.bodySmall.copyWith(color: tone.ink),
                    ),
                    if (evidence != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        evidence,
                        style: AppTypography.labelMedium.copyWith(
                          color: tone.ink,
                        ),
                      ),
                    ],
                    if (coverage != null)
                      Text(
                        coverage,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
