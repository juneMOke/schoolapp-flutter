import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bilan : trois compteurs, la planche des élèves photographiés pour un
/// contrôle d'un coup d'œil, la reprise des absents et passés, et Terminer.
class SessionSummaryView extends StatelessWidget {
  final SessionSummary state;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  const SessionSummaryView({
    super.key,
    required this.state,
    required this.onResume,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final registry = getIt<StudentPhotoRegistry>();
    final waiting = state.photographed
        .where((i) => registry.refOf(i.student.id)?.isPending ?? false)
        .length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        children: [
          Container(
            width: AppDimensions.photoSessionSummaryMedallion,
            height: AppDimensions.photoSessionSummaryMedallion,
            decoration: const BoxDecoration(
              color: AppColors.photoDoneSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: AppSpacing.xxl,
              color: AppColors.photoDone,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.photoSessionDoneTitle(state.klass.name),
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: [
              _Count(
                value: state.photographed.length,
                label: l10n.photoSessionDoneCount,
                color: AppColors.photoDone,
              ),
              _Count(
                value: state.absent,
                label: l10n.photoSessionAbsentCount,
                color: AppColors.photoWaitInk,
              ),
              _Count(
                value: state.skipped,
                label: l10n.photoSessionSkippedCount,
                color: AppColors.textMuted,
              ),
            ],
          ),
          if (state.photographed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final item in state.photographed)
                  PersonAvatar(
                    firstName: item.student.firstName,
                    lastName: item.student.lastName,
                    personId: item.student.id,
                    size: AppDimensions.photoSessionSummaryAvatar,
                    studentPhotoOf: item.student.id,
                    semanticLabel: item.student.fullName,
                  ),
              ],
            ),
          ],
          if (waiting > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.photoSessionPendingWarning(waiting),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.photoWaitInk,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              if (state.resumable > 0)
                EteeloButton.secondary(
                  label: l10n.photoSessionResume(state.resumable),
                  icon: Icons.replay_rounded,
                  fullWidth: false,
                  onPressed: onResume,
                ),
              EteeloButton.primary(
                label: l10n.photoSessionFinish,
                fullWidth: false,
                onPressed: onFinish,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _Count({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.photoSessionCountTile,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.headlineLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
