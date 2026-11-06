import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le déclencheur : disque blanc de 68 dp cerclé de blanc translucide. Inactif
/// (estompé) tant que le flux n'est pas en direct.
///
/// Un vrai bouton sur le poste et le web : une étape de tabulation, Entrée
/// et Espace, curseur main ; le survol éclaire l'anneau, le focus clavier
/// l'entoure d'or.
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

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return EteeloActivatable(
      onActivate: widget.onPressed,
      semanticLabel: widget.semanticLabel,
      builder: (context, highlight) => Listener(
        onPointerDown: enabled ? (_) => _setPressed(true) : null,
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
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
                  color: highlight.focused
                      ? AppColors.orDoux
                      : highlight.hovered
                      ? AppColors.onPhotoCapture
                      : AppColors.onPhotoCaptureRing,
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

/// Bouton pilule de 48 dp sur fond sombre : secondaire (cerclé, voilé) ou
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

/// Le bouton carré de fermeture (48 × 48, rayon 12) des panneaux sombres.
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
