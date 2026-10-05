import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête du panneau : le sur-titre or (« Photo de l'élève », ou
/// « Vérifier & recadrer » au recadrage), le nom de l'élève, et la croix —
/// absente pendant l'enregistrement.
class CaptureHeader extends StatelessWidget {
  final String studentName;
  final bool reviewing;
  final VoidCallback? onClose;

  const CaptureHeader({
    super.key,
    required this.studentName,
    required this.reviewing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onClose = this.onClose;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (reviewing ? l10n.photoReviewEyebrow : l10n.photoEyebrow)
                    .toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.orDoux,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.onPhotoCapture,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          PhotoDarkCloseButton(onPressed: onClose, tooltip: l10n.photoClose),
      ],
    );
  }
}
