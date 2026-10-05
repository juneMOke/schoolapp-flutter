import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_camera_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_flash.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La prise de vue d'un élève : qui il est, où en est la classe, le viseur,
/// et la barre Passer · déclencheur · Absent.
class SessionShootPanel extends StatelessWidget {
  final SessionShooting state;
  final bool online;
  final VoidCallback onShoot;
  final VoidCallback onSkip;
  final VoidCallback onAbsent;
  final VoidCallback onImport;
  final VoidCallback onSwitch;
  final VoidCallback onAdvance;
  final VoidCallback onRetake;

  const SessionShootPanel({
    super.key,
    required this.state,
    required this.online,
    required this.onShoot,
    required this.onSkip,
    required this.onAbsent,
    required this.onImport,
    required this.onSwitch,
    required this.onAdvance,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = state.current.student;
    final camera = state.camera;
    final opened = camera is CameraOpened ? camera : null;
    final flash = state.flash;
    final progress = state.queue.isEmpty
        ? 0.0
        : state.handled / state.queue.length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: LinearGradient(
          begin: Alignment(-0.34, -1),
          end: Alignment(0.34, 1),
          colors: [AppColors.photoCaptureTop, AppColors.photoCaptureBottom],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PersonAvatar(
                firstName: student.firstName,
                lastName: student.lastName,
                personId: student.id,
                size: AppDimensions.photoSessionHeaderAvatar,
                studentPhotoOf: student.id,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.photoSessionProgress(
                        state.index + 1,
                        state.queue.length,
                      ),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.orDoux,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: student.familyName,
                        children: [
                          TextSpan(
                            text: ' ${student.firstName}',
                            style: const TextStyle(
                              color: AppColors.onPhotoCaptureMuted,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.onPhotoCapture,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressBar(value: progress),
          const SizedBox(height: AppSpacing.md),
          Stack(
            children: [
              PhotoViewfinder(
                session: opened?.session,
                tip: l10n.photoSessionTip,
                overlay: switch (camera) {
                  CameraUnavailable(:final reason) => CaptureProblemCard(
                    icon: Icons.videocam_off_rounded,
                    title: reason == CameraBlockReason.denied
                        ? l10n.photoCameraBlockedTitle
                        : l10n.photoNoCameraTitle,
                    message: l10n.photoSessionImportInstead,
                    actionLabel: l10n.photoImportAction,
                    onAction: onImport,
                  ),
                  null => const Center(
                    child: CircularProgressIndicator(color: AppColors.orDoux),
                  ),
                  _ => null,
                },
              ),
              if (flash != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.photoViewfinderRadius,
                    ),
                    child: SessionFlashOverlay(
                      key: ValueKey(flash),
                      flash: flash,
                      queued: !online,
                      onAdvance: onAdvance,
                      onRetake: onRetake,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PhotoDarkPillButton(
                    label: l10n.photoSessionSkip,
                    icon: Icons.skip_next_rounded,
                    onPressed: state.busy ? null : onSkip,
                  ),
                ),
              ),
              PhotoShutterButton(
                semanticLabel: l10n.photoShutter,
                onPressed: opened != null && !state.busy && flash == null
                    ? onShoot
                    : null,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PhotoDarkPillButton(
                    label: l10n.photoSessionAbsent,
                    icon: Icons.person_off_outlined,
                    onPressed: state.busy ? null : onAbsent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            children: [
              TextButton.icon(
                onPressed: state.busy ? null : onImport,
                icon: const Icon(
                  Icons.upload_rounded,
                  size: AppDimensions.photoIconSm,
                ),
                label: Text(l10n.photoSessionImportForStudent),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onPhotoCaptureMuted,
                ),
              ),
              if (opened != null && opened.canSwitch)
                TextButton.icon(
                  onPressed: onSwitch,
                  icon: const Icon(
                    Icons.cameraswitch_rounded,
                    size: AppDimensions.photoIconSm,
                  ),
                  label: Text(l10n.photoSwitchCamera),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onPhotoCaptureMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 4 dp, du terre cuite à l'or : la part des élèves traités.
class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: SizedBox(
        height: AppDimensions.photoSessionProgressBar,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.onPhotoCaptureVeil),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.terreCuite, AppColors.orDoux],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
