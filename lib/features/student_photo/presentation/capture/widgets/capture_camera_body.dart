import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le titre et la phrase d'une caméra empêchée. Sur le web, un refus se
/// lève dans le navigateur, pour ce site : la phrase le dit.
({String title, String message}) cameraBlockTexts(
  AppLocalizations l10n,
  CameraBlockReason reason, {
  bool web = kIsWeb,
}) => switch (reason) {
  CameraBlockReason.denied => (
    title: l10n.photoCameraBlockedTitle,
    message: web
        ? l10n.photoCameraBlockedWebMessage
        : l10n.photoCameraBlockedMessage,
  ),
  CameraBlockReason.none => (
    title: l10n.photoNoCameraTitle,
    message: l10n.photoNoCameraMessage,
  ),
  CameraBlockReason.insecureContext => (
    title: l10n.photoCameraInsecureTitle,
    message: l10n.photoCameraInsecureMessage,
  ),
};

/// Le viseur et sa barre (Importer · déclencheur · bascule) — pour une
/// caméra en route, en direct, absente ou refusée. L'import reste toujours
/// possible.
class CaptureCameraBody extends StatelessWidget {
  final StudentPhotoCaptureState state;
  final VoidCallback onImport;
  final VoidCallback onShoot;
  final VoidCallback onSwitch;

  /// Redemande la caméra après un refus ou une absence.
  final VoidCallback onRetry;

  /// Cf. [PhotoViewfinder.maxHeight].
  final double? viewfinderMaxHeight;

  const CaptureCameraBody({
    super.key,
    required this.state,
    required this.onImport,
    required this.onShoot,
    required this.onSwitch,
    required this.onRetry,
    this.viewfinderMaxHeight,
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
          maxHeight: viewfinderMaxHeight,
          overlay: switch (state) {
            CaptureStarting() => const _CameraStarting(),
            CaptureBlocked(:final reason) => CaptureProblemCard(
              icon: Icons.videocam_off_rounded,
              title: cameraBlockTexts(l10n, reason).title,
              message: cameraBlockTexts(l10n, reason).message,
              actionLabel: l10n.photoImportAction,
              onAction: onImport,
              onRetry: reason.canRetry ? onRetry : null,
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

  /// « Réessayer » : redemande la caméra. Nul, pas de second bouton.
  final VoidCallback? onRetry;

  const CaptureProblemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
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
          secondaryAction: onRetry == null
              ? null
              : PhotoDarkPillButton(
                  label: AppLocalizations.of(context)!.photoRetry,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
        ),
      ),
    );
  }
}
