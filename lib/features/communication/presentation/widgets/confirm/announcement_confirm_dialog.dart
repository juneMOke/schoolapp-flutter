import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le garde-fou de l'envoi direct : aucun circuit de validation, donc un
/// récapitulatif avant le geste irréversible. Rend `true` pour poursuivre.
Future<bool> showAnnouncementConfirmDialog(
  BuildContext context, {
  required AnnouncementEditorState state,
  required AnnouncementReach? reach,
  required DateTime now,
}) async {
  final confirmed = await EteeloFormDialog.show<bool>(
    context,
    _ConfirmDialog(state: state, reach: reach, now: now),
  );
  return confirmed ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  final AnnouncementEditorState state;
  final AnnouncementReach? reach;
  final DateTime now;

  const _ConfirmDialog({
    required this.state,
    required this.reach,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheduled = state.sendMode == AnnouncementSendMode.scheduled;
    final reach = this.reach;
    final count = reach?.reachableMessages;
    final unreachable = reach?.unreachableMessages ?? 0;
    final audience = l10n.audienceSummary(state.content.audience);
    return EteeloFormDialog(
      eyebrow: l10n.communicationConfirmEyebrow,
      maxWidth: AppDimensions.communicationConfirmModalMaxWidth,
      title: switch ((scheduled, count)) {
        (false, final int n) => l10n.communicationConfirmSendTitle(n),
        (true, final int n) => l10n.communicationConfirmScheduleTitle(n),
        (false, null) => l10n.communicationConfirmSendTitleUnknown,
        (true, null) => l10n.communicationConfirmScheduleTitleUnknown,
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            label: l10n.communicationConfirmRecipients,
            value: reach == null
                ? audience
                : l10n.communicationConfirmRecipientsValue(
                    audience,
                    reach.students,
                  ),
          ),
          _Row(
            label: l10n.communicationChannelsLabel,
            value: state.content.channels.map(l10n.channelLabel).join(', '),
          ),
          _Row(
            label: l10n.communicationSendLabel,
            value: scheduled
                ? AnnouncementDates.moment(l10n, state.scheduledAt, now)
                : l10n.communicationConfirmImmediate,
          ),
          if (unreachable > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            EteeloNotice.warning(
              l10n.communicationReachUnreachable(
                unreachable,
                reach!.guardiansWithoutPhone,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.communicationConfirmIrreversible,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        EteeloButton.secondary(
          label: l10n.communicationConfirmEdit,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: scheduled
              ? l10n.communicationSchedule
              : l10n.communicationConfirmSendNow,
          icon: scheduled ? Icons.schedule_send_outlined : Icons.send_outlined,
          onPressed: () => Navigator.of(context).pop(true),
          fullWidth: false,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
