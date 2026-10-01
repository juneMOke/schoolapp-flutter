import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_sync_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// La personne d'une ligne de registre : initiales et pastille de synchro,
/// ligne de tête, ligne d'appoint, et un badge facultatif ([trailing], le
/// « VAC · H » d'un vacataire). Partagé par la carte et la ligne.
class PresencePersonHeading extends StatelessWidget {
  final PresenceRowView row;
  final Widget? trailing;

  const PresencePersonHeading({super.key, required this.row, this.trailing});

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        PersonSyncAvatar(
          firstName: row.firstName,
          lastName: row.lastName,
          personId: row.personId,
          sync: row.sync,
          size: AppDimensions.presenceMarkAvatarSize,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                row.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
