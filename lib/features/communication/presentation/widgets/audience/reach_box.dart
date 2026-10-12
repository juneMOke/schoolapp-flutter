import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'encart de portée, sous le sélecteur : combien de messages partiraient,
/// calculé par le serveur — jamais par la tablette, qui ne connaît ni les
/// tuteurs ni leurs numéros.
class ReachBox extends StatelessWidget {
  final AnnouncementReachState state;
  final VoidCallback onRetry;

  const ReachBox({super.key, required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reach = state.reach;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.billingHelpSurface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.billingHelpBorder),
        ),
        child: switch (state.status) {
          ReachStatus.invalid => _Line(
            icon: Icons.group_outlined,
            text: l10n.communicationReachInvalid,
            color: AppColors.textSecondary,
          ),
          ReachStatus.loading when reach == null => const _Skeleton(),
          ReachStatus.failure => Row(
            children: [
              Expanded(
                child: _Line(
                  icon: Icons.cloud_off_outlined,
                  text: l10n.communicationReachFailed,
                  color: AppColors.textSecondary,
                ),
              ),
              EteeloButton.ghost(
                label: l10n.communicationRetry,
                icon: Icons.refresh,
                onPressed: onRetry,
                fullWidth: false,
              ),
            ],
          ),
          _ => _Counts(
            reach: reach!,
            overdue: state.audience is OverdueAudience,
            refreshing: state.status == ReachStatus.loading,
          ),
        },
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  final AnnouncementReach reach;
  final bool overdue;
  final bool refreshing;

  const _Counts({
    required this.reach,
    required this.overdue,
    required this.refreshing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unreachable = reach.unreachableMessages;
    return Opacity(
      opacity: refreshing ? 0.6 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.communicationReachHeadline(
              reach.reachableMessages,
              reach.messages,
            ),
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.bleuArdoise,
            ),
          ),
          Text(
            l10n.communicationReachDetail(reach.students, reach.guardians),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (reach.messages == 0 && overdue) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              icon: Icons.info_outline,
              text: l10n.communicationReachNoOverdue,
              color: AppColors.ambreInk,
            ),
          ],
          if (unreachable > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              icon: Icons.phone_disabled_outlined,
              text: l10n.communicationReachUnreachable(
                unreachable,
                reach.guardiansWithoutPhone,
              ),
              color: AppColors.ambreInk,
            ),
          ],
          if (reach.whatsappEnabled == false) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              icon: Icons.chat_bubble_outline,
              text: l10n.communicationRefusalChannelDisabled,
              color: AppColors.ambreInk,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Line({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(color: color),
        ),
      ),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.communicationReachLoading,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloSkeletonBox(width: 220, height: 16),
        SizedBox(height: AppSpacing.sm),
        EteeloSkeletonBox(width: 160, height: 12),
      ],
    ),
  );
}
