import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_status_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La file de la classe : un élève par ligne, son statut, l'élève courant
/// souligné. Toucher un élève à photographier, absent ou passé le rend
/// courant ; un élève photographié est inerte.
class SessionQueuePanel extends StatelessWidget {
  final SessionShooting state;
  final bool online;
  final ValueChanged<int> onSelect;

  const SessionQueuePanel({
    super.key,
    required this.state,
    required this.online,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photographed = state.queue
        .where((i) => i.status == SessionItemStatus.photographed)
        .length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.photoSessionQueueTitle(state.klass.name),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  l10n.photoSessionQueueCount(photographed),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.queue.length,
              itemBuilder: (context, i) => _QueueRow(
                item: state.queue[i],
                current: i == state.index,
                online: online,
                onTap: state.queue[i].status == SessionItemStatus.photographed
                    ? null
                    : () => onSelect(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final SessionItem item;
  final bool current;
  final bool online;
  final VoidCallback? onTap;

  const _QueueRow({
    required this.item,
    required this.current,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final student = item.student;
    return Material(
      color: current ? AppColors.photoQueueCurrent : AppColors.surfaceRaised,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.photoSessionQueueRow,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: current ? AppColors.terreCuite : Colors.transparent,
                width: AppDimensions.photoSessionCurrentRule,
              ),
            ),
          ),
          child: Row(
            children: [
              PersonAvatar(
                firstName: student.firstName,
                lastName: student.lastName,
                personId: student.id,
                size: AppDimensions.photoSessionQueueAvatar,
                studentPhotoOf: student.id,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.familyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      student.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SessionStatusChip(
                studentId: student.id,
                status: item.status,
                online: online,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bandeau hors connexion, au-dessus de la file, tant qu'une photo attend.
class SessionOfflineBanner extends StatelessWidget {
  final int pending;

  const SessionOfflineBanner({super.key, required this.pending});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.bleuArdoiseSoft,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.bleuArdoise),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.photoSessionOfflineBanner(pending),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
