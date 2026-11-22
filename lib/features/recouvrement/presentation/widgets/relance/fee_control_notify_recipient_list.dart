import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellé de section de la relance : capitales, discret (« MESSAGE »,
/// « DESTINATAIRES ») — celui de la maquette.
class FeeControlNotifySectionLabel extends StatelessWidget {
  final String text;

  const FeeControlNotifySectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedAa),
    ),
  );
}

/// Les destinataires de la relance : parent, téléphone, « pour {élève} ».
///
/// **Ceux sans téléphone sont listés à part** (spec §5, ligne O4) : ils
/// figurent sur la relance, mais ne seront pas joints par elle — mieux vaut le
/// savoir avant d'envoyer qu'après.
class FeeControlNotifyRecipientList extends StatelessWidget {
  final List<FeeControlNotifyRecipient> recipients;

  const FeeControlNotifyRecipientList({super.key, required this.recipients});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reachable = [
      for (final r in recipients)
        if (r.hasPhone) r,
    ];
    final unreachable = [
      for (final r in recipients)
        if (!r.hasPhone) r,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FeeControlNotifySectionLabel(l10n.feeControlNotifyRecipients),
        if (reachable.isNotEmpty) _Frame(recipients: reachable),
        if (unreachable.isNotEmpty) ...[
          if (reachable.isNotEmpty) const SizedBox(height: AppSpacing.md),
          FeeControlNotifySectionLabel(
            l10n.feeControlNotifyWithoutPhone(unreachable.length),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.feeControlNotifyWithoutPhoneNote,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _Frame(recipients: unreachable),
        ],
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  final List<FeeControlNotifyRecipient> recipients;

  const _Frame({required this.recipients});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(
        AppDimensions.recoveryNotifyFrameRadius,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, recipient) in recipients.indexed) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.border),
          _RecipientRow(recipient: recipient),
        ],
      ],
    ),
  );
}

class _RecipientRow extends StatelessWidget {
  final FeeControlNotifyRecipient recipient;

  const _RecipientRow({required this.recipient});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parent = recipient.parentName;
    final name = parent ?? l10n.feeControlNotifyUnknownParent;
    final words = (parent ?? recipient.studentName).split(' ');
    final forStudent = l10n.feeControlNotifyRecipientFor(recipient.studentName);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          PersonAvatar(
            lastName: words.first,
            firstName: words.length > 1 ? words.last : '',
            // L'élève est la seule identité stable : le parent n'a pas d'id.
            personId: recipient.studentId,
            size: AvatarSize.sm,
            variant: parent == null
                ? AvatarVariant.outlined
                : AvatarVariant.solid,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: parent == null
                        ? AppColors.textMutedAa
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  recipient.hasPhone
                      ? '${recipient.phoneNumber} · $forStudent'
                      : forStudent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMutedAa,
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
