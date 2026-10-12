import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les faits d'un communiqué envoyé : quand, à qui, combien de messages sont
/// partis, par où. La portée est celle figée à l'envoi.
class AnnouncementMetaGrid extends StatelessWidget {
  final Announcement announcement;
  final DateTime now;

  const AnnouncementMetaGrid({
    super.key,
    required this.announcement,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sentAt = announcement.sentAt;
    final reach = announcement.reachAtSend;
    final items = [
      (
        l10n.communicationStatusSent,
        sentAt == null ? '—' : AnnouncementDates.moment(l10n, sentAt, now),
      ),
      (
        l10n.communicationConfirmRecipients,
        reach == null
            ? l10n.audienceSummary(announcement.content.audience)
            : l10n.communicationConfirmRecipientsValue(
                l10n.audienceSummary(announcement.content.audience),
                reach.students,
              ),
      ),
      (
        l10n.communicationDetailMessages,
        reach == null
            ? '—'
            : l10n.communicationReachSentShort(
                reach.reachableMessages,
                reach.messages,
              ),
      ),
      (
        l10n.communicationChannelsLabel,
        l10n.listOf(announcement.content.channels.map(l10n.channelLabel)),
      ),
    ];
    return CommunicationCard(
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          for (final (label, value) in items)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppDimensions.communicationMetaItemMinWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
