import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le viseur et sa barre (Importer · déclencheur · bascule) — pour une
/// caméra en route, en direct, absente ou refusée. L'import reste toujours
/// possible.
class CaptureCameraBody extends StatelessWidget {
  final StudentPhotoCaptureState state;
  final VoidCallback onImport;
  final VoidCallback onShoot;
  final VoidCallback onSwitch;

  const CaptureCameraBody({
    super.key,
    required this.state,
    required this.onImport,
    required this.onShoot,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = this.state;
    final live = state is CaptureLive ? state : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhotoViewfinder(
          session: live?.session,
          tip: l10n.photoCaptureTip,
          overlay: switch (state) {
            CaptureStarting() => const _CameraStarting(),
            CaptureBlocked(:final reason) => CaptureProblemCard(
              icon: Icons.videocam_off_rounded,
              title: reason == CameraBlockReason.denied
                  ? l10n.photoCameraBlockedTitle
                  : l10n.photoNoCameraTitle,
              message: reason == CameraBlockReason.denied
                  ? l10n.photoCameraBlockedMessage
                  : l10n.photoNoCameraMessage,
              actionLabel: l10n.photoImportAction,
              onAction: onImport,
            ),
            _ => null,
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PhotoDarkPillButton(
                  label: l10n.photoImport,
                  icon: Icons.upload_rounded,
                  onPressed: onImport,
                ),
              ),
            ),
            PhotoShutterButton(
              semanticLabel: l10n.photoShutter,
              onPressed: live != null && !live.shooting ? onShoot : null,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: live != null && live.canSwitch
                    ? PhotoDarkPillButton(
                        label: l10n.photoSwitchCamera,
                        icon: Icons.cameraswitch_rounded,
                        onPressed: onSwitch,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// La demande d'accès : un médaillon caméra et la consigne « Autoriser ».
class _CameraStarting extends StatelessWidget {
  const _CameraStarting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: AppSpacing.xxl,
              color: AppColors.orDoux,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.photoCameraStarting,
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.onPhotoCapture,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.photoCameraAllowHint,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onPhotoCaptureMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La carte blanche d'un empêchement (caméra absente ou refusée, fichier
/// illisible) : l'anatomie partagée des états vides, avec son issue.
class CaptureProblemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const CaptureProblemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EteeloEmptyResult(
          label: title,
          description: message,
          medallionIcon: icon,
          accentColor: AppColors.terreCuite,
          minHeight: 0,
          cardPadding: const EdgeInsets.all(AppSpacing.xl),
          autofocusPrimaryAction: true,
          primaryAction: PhotoDarkPillButton(
            label: actionLabel,
            icon: Icons.upload_rounded,
            onPressed: onAction,
            primary: true,
          ),
        ),
      ),
    );
  }
}
