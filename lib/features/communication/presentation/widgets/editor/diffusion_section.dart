import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_section_card.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/schedule_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section 3 — par où, et quand.
class DiffusionSection extends StatelessWidget {
  final AnnouncementEditorState state;
  final DateTime now;
  final ValueChanged<AnnouncementChannel> onToggleChannel;
  final ValueChanged<AnnouncementSendMode> onSendMode;
  final ValueChanged<DateTime> onScheduledAt;
  final int number;

  const DiffusionSection({
    super.key,
    required this.number,
    required this.state,
    required this.now,
    required this.onToggleChannel,
    required this.onSendMode,
    required this.onScheduledAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locked = state.inputLocked;
    final scheduled = state.sendMode == AnnouncementSendMode.scheduled;
    return EditorSectionCard(
      number: number,
      title: l10n.communicationSectionDiffusion,
      subtitle: l10n.communicationSectionDiffusionHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label(l10n.communicationChannelsLabel),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final channel in AnnouncementChannel.values)
                EteeloFilterChip(
                  label: l10n.channelLabel(channel),
                  icon: Icons.chat_outlined,
                  selected: state.content.channels.contains(channel),
                  color: AppColors.feeStatusPaid,
                  soft: AppColors.feeStatusPaidSoft,
                  ink: AppColors.feeStatusPaid,
                  onTap: locked ? null : () => onToggleChannel(channel),
                ),
            ],
          ),
          if (state.hasIssueOn(AnnouncementField.channels))
            _Error(l10n.communicationNoChannel),
          const SizedBox(height: AppSpacing.lg),
          _Label(l10n.communicationSendLabel),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedTabFilter<AnnouncementSendMode>(
              enabled: !locked,
              semanticsLabel: l10n.communicationSendLabel,
              options: [
                SegmentedTabOption(
                  label: l10n.communicationSendNow,
                  value: AnnouncementSendMode.now,
                  icon: Icons.send_outlined,
                ),
                SegmentedTabOption(
                  label: l10n.communicationSendLater,
                  value: AnnouncementSendMode.scheduled,
                  icon: Icons.schedule_send_outlined,
                ),
              ],
              selected: state.sendMode,
              onSelected: onSendMode,
            ),
          ),
          if (scheduled) ...[
            const SizedBox(height: AppSpacing.md),
            ScheduleFields(
              instant: state.scheduledAt,
              now: now,
              onChanged: locked ? null : onScheduledAt,
              errorText: state.hasIssueOn(AnnouncementField.scheduledAt)
                  ? l10n.communicationScheduleNotFuture
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.communicationScheduleHint(
                AnnouncementDates.moment(l10n, state.scheduledAt, now),
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
    ),
  );
}

class _Error extends StatelessWidget {
  final String text;

  const _Error(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      ),
    ),
  );
}
