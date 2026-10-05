import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le déclencheur : disque blanc de 68 dp cerclé de blanc translucide. Inactif
/// (estompé) tant que le flux n'est pas en direct.
class PhotoShutterButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String semanticLabel;

  const PhotoShutterButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
  });

  static const double diameter = AppDimensions.photoShutter;

  @override
  State<PhotoShutterButton> createState() => _PhotoShutterButtonState();
}

class _PhotoShutterButtonState extends State<PhotoShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.35,
          duration: AppMotion.micro,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: reduceMotion ? Duration.zero : AppMotion.micro,
            child: Container(
              width: PhotoShutterButton.diameter,
              height: PhotoShutterButton.diameter,
              decoration: BoxDecoration(
                color: AppColors.onPhotoCapture,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.onPhotoCaptureRing,
                  width: AppDimensions.photoShutterRing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton pilule de 44 dp sur fond sombre : secondaire (cerclé, voilé) ou
/// primaire (terre cuite plein).
class PhotoDarkPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;

  const PhotoDarkPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });

  static const double height = AppDimensions.photoDarkButton;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(height, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      foregroundColor: const WidgetStatePropertyAll(AppColors.onPhotoCapture),
      backgroundColor: WidgetStatePropertyAll(
        primary ? AppColors.terreCuite : AppColors.onPhotoCaptureFaint,
      ),
      side: WidgetStatePropertyAll(
        primary
            ? BorderSide.none
            : const BorderSide(
                color: AppColors.onPhotoCaptureBorder,
                width: AppDimensions.photoHairline,
              ),
      ),
      textStyle: const WidgetStatePropertyAll(AppTypography.labelLarge),
    );
    final iconData = icon;
    if (iconData == null) {
      return TextButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(iconData, size: AppDimensions.photoIconMd),
      label: Text(label),
    );
  }
}

/// Le petit bouton carré de fermeture (40 × 40, rayon 12) des panneaux sombres.
class PhotoDarkCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const PhotoDarkCloseButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.close_rounded),
      color: AppColors.onPhotoCapture,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppDimensions.photoCloseButton),
        backgroundColor: AppColors.onPhotoCaptureFaint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.photoCloseRadius),
        ),
      ),
    );
  }
}
