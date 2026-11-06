import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_progress_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Qui est devant l'objectif : son avatar, « Élève i / N », son nom ; puis
/// la barre de progression de la classe.
class SessionStudentHeader extends StatelessWidget {
  final SessionShooting state;

  const SessionStudentHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = state.current.student;
    final progress = state.queue.isEmpty
        ? 0.0
        : state.handled / state.queue.length;
    return Column(
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
        SessionProgressBar(value: progress),
      ],
    );
  }
}

/// Les gestes de la prise : Passer · déclencheur · Absent, puis « Importer
/// un fichier » et, s'il y a deux objectifs, « Changer de caméra ».
///
/// [compact] (séance en paysage) : ces deux derniers en icônes de 48 dp,
/// libellé en info-bulle et pour le lecteur d'écran. Avec leurs libellés,
/// ils prenaient deux lignes de 48 dp dans une colonne de ~330 : la
/// hauteur d'un téléphone couché ne les loge pas avec l'élève et le
/// déclencheur.
class SessionShootActions extends StatelessWidget {
  final SessionShooting state;
  final bool compact;
  final VoidCallback onShoot;
  final VoidCallback onSkip;
  final VoidCallback onAbsent;
  final VoidCallback onImport;
  final VoidCallback onSwitch;

  const SessionShootActions({
    super.key,
    required this.state,
    this.compact = false,
    required this.onShoot,
    required this.onSkip,
    required this.onAbsent,
    required this.onImport,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final camera = state.camera;
    final opened = camera is CameraOpened ? camera : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              onPressed: opened != null && !state.busy && state.flash == null
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
          children: compact
              ? [
                  _iconAction(
                    Icons.upload_rounded,
                    l10n.photoSessionImportForStudent,
                    state.busy ? null : onImport,
                  ),
                  if (opened != null && opened.canSwitch)
                    _iconAction(
                      Icons.cameraswitch_rounded,
                      l10n.photoSwitchCamera,
                      onSwitch,
                    ),
                ]
              : [
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
    );
  }

  static Widget _iconAction(
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    color: AppColors.onPhotoCaptureMuted,
    constraints: const BoxConstraints(
      minWidth: AppDimensions.minTouchTarget,
      minHeight: AppDimensions.minTouchTarget,
    ),
    icon: Icon(icon, size: AppDimensions.photoIconMd),
  );
}
