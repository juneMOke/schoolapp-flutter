import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_camera_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_flash.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le viseur de la séance et ce qui le recouvre : la caméra absente ou
/// refusée, le sablier de l'ouverture, le flash après une prise.
///
/// Il reçoit une `GlobalKey` de la vue de prise : d'une disposition à
/// l'autre (colonne, paysage), c'est le même élément qui change de parent —
/// l'aperçu n'est ni démonté ni rouvert.
class SessionShootViewfinder extends StatelessWidget {
  final SessionShooting state;
  final bool online;
  final VoidCallback onImport;
  final VoidCallback onRetryCamera;
  final VoidCallback onAdvance;
  final VoidCallback onRetake;

  const SessionShootViewfinder({
    super.key,
    required this.state,
    required this.online,
    required this.onImport,
    required this.onRetryCamera,
    required this.onAdvance,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final camera = state.camera;
    final opened = camera is CameraOpened ? camera : null;
    final flash = state.flash;
    return Stack(
      children: [
        PhotoViewfinder(
          session: opened?.session,
          tip: l10n.photoSessionTip,
          overlay: switch (camera) {
            CameraUnavailable(:final reason) => CaptureProblemCard(
              icon: Icons.videocam_off_rounded,
              title: cameraBlockTexts(l10n, reason).title,
              // Sans caméra, la séance continue à l'import ; refusée ou en
              // http, on dit d'abord comment la retrouver.
              message: reason == CameraBlockReason.none
                  ? l10n.photoSessionImportInstead
                  : cameraBlockTexts(l10n, reason).message,
              actionLabel: l10n.photoImportAction,
              onAction: onImport,
              onRetry: reason.canRetry ? onRetryCamera : null,
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
    );
  }
}
