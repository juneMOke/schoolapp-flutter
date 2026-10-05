import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La photo en préparation : un anneau or doux, ou « Enregistrement… » quand
/// les animations sont réduites.
class CaptureSavingBody extends StatelessWidget {
  const CaptureSavingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return _Centered(
      children: [
        if (!reduceMotion)
          const SizedBox.square(
            dimension: AppDimensions.photoSavedCheck,
            child: CircularProgressIndicator(color: AppColors.orDoux),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.photoSaving,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onPhotoCapture,
          ),
        ),
      ],
    );
  }
}

/// « Photo enregistrée » : la photo, une coche vert savane, et la phrase qui
/// dit ce qui change. La modale se ferme d'elle-même.
class CaptureSavedBody extends StatelessWidget {
  final Uint8List photo;

  const CaptureSavedBody({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return _Centered(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: Image.memory(
                photo,
                width: AppDimensions.photoSavingPreview,
                height: AppDimensions.photoSavingPreview,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.square(
                  dimension: AppDimensions.photoSavingPreview,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
                duration: reduceMotion ? Duration.zero : AppMotion.pop,
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: AppDimensions.photoSavedCheck,
                  height: AppDimensions.photoSavedCheck,
                  decoration: const BoxDecoration(
                    color: AppColors.photoDone,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.onPhotoCapture,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.photoSaved,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.onPhotoCapture,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.photoSavedMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onPhotoCaptureMuted,
          ),
        ),
      ],
    );
  }
}

/// La photo n'a pas pu être gardée sur le poste : elle reste, on réessaie.
class CaptureSaveFailedBody extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onRetake;

  const CaptureSaveFailedBody({
    super.key,
    required this.onRetry,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloErrorResult(
      type: EteeloErrorType.unknown,
      title: l10n.photoSaveFailedTitle,
      message: l10n.photoSaveFailedMessage,
      minHeight: 0,
      cardPadding: const EdgeInsets.all(AppSpacing.xl),
      secondaryAction: PhotoDarkPillButton(
        label: l10n.photoRetake,
        onPressed: onRetake,
      ),
      primaryAction: PhotoDarkPillButton(
        label: l10n.photoRetry,
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
        primary: true,
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final List<Widget> children;

  const _Centered({required this.children});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
