import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_crop_view.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vérifier et recadrer : la zone carrée, puis Reprendre (ou Autre fichier)
/// et « Utiliser cette photo ».
class CaptureReviewBody extends StatelessWidget {
  final CaptureReview review;
  final ValueChanged<CropWindow> onAdjust;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  const CaptureReviewBody({
    super.key,
    required this.review,
    required this.onAdjust,
    required this.onRetake,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhotoCropView(
          source: review.source,
          window: review.window,
          mirror: review.mirror,
          zoomLabel: l10n.photoZoom,
          onChanged: onAdjust,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            PhotoDarkPillButton(
              label: review.origin == PhotoOrigin.camera
                  ? l10n.photoRetake
                  : l10n.photoOtherFile,
              icon: review.origin == PhotoOrigin.camera
                  ? Icons.replay_rounded
                  : Icons.image_outlined,
              onPressed: onRetake,
            ),
            PhotoDarkPillButton(
              label: l10n.photoUse,
              icon: Icons.check_rounded,
              onPressed: onUse,
              primary: true,
            ),
          ],
        ),
      ],
    );
  }
}
