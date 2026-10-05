import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Les six statuts d'un élève de la file, tels qu'on les lit.
enum SessionDisplayStatus { todo, sending, done, queued, absent, skipped }

/// Le statut affiché : celui de la séance, et pour une photo prise, ce que
/// l'envoi en est devenu (en route, en file hors connexion, accusé).
SessionDisplayStatus displayStatusOf(
  SessionItemStatus status,
  StudentPhotoRef? ref, {
  required bool online,
}) => switch (status) {
  SessionItemStatus.todo => SessionDisplayStatus.todo,
  SessionItemStatus.absent => SessionDisplayStatus.absent,
  SessionItemStatus.skipped => SessionDisplayStatus.skipped,
  SessionItemStatus.photographed =>
    !(ref?.isPending ?? false)
        ? SessionDisplayStatus.done
        : (online ? SessionDisplayStatus.sending : SessionDisplayStatus.queued),
};

/// La puce de statut d'un élève, lue en texte par le lecteur d'écran.
class SessionStatusChip extends StatelessWidget {
  final String studentId;
  final SessionItemStatus status;
  final bool online;

  const SessionStatusChip({
    super.key,
    required this.studentId,
    required this.status,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentPhotoRef?>(
      valueListenable: getIt<StudentPhotoRegistry>().watch(studentId),
      builder: (context, ref, _) =>
          _chip(context, displayStatusOf(status, ref, online: online)),
    );
  }

  Widget _chip(BuildContext context, SessionDisplayStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final (label, icon, ink, fill) = switch (status) {
      SessionDisplayStatus.todo => (
        l10n.photoStatusTodo,
        Icons.photo_camera_outlined,
        AppColors.textSecondary,
        AppColors.surfaceAlt,
      ),
      SessionDisplayStatus.sending => (
        l10n.photoStatusSending,
        Icons.sync_rounded,
        AppColors.bleuArdoise,
        AppColors.bleuArdoiseSoft,
      ),
      SessionDisplayStatus.done => (
        l10n.photoStatusDone,
        Icons.check_circle_rounded,
        AppColors.photoDone,
        AppColors.photoDoneSoft,
      ),
      SessionDisplayStatus.queued => (
        l10n.photoStatusQueued,
        Icons.cloud_off_rounded,
        AppColors.photoWaitInk,
        AppColors.photoWaitSoft,
      ),
      SessionDisplayStatus.absent => (
        l10n.photoStatusAbsent,
        Icons.person_off_outlined,
        AppColors.photoWaitInk,
        AppColors.photoWaitSoft,
      ),
      SessionDisplayStatus.skipped => (
        l10n.photoStatusSkipped,
        Icons.skip_next_rounded,
        AppColors.textMuted,
        AppColors.surfaceAlt,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.photoIconXs, color: ink),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.labelSmall.copyWith(color: ink)),
        ],
      ),
    );
  }
}
