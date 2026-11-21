import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Un bouton icône rond de 48 dp, bordé à sa teinte (EDT §4.6 C) : Imprimer,
/// Copier et Abandonner sous 600, avec leur info-bulle et leur nom vocal.
class TimetableIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color tone;

  const TimetableIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = AppColors.bleuArdoise,
  });

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(
      width: AppDimensions.minTouchTarget,
      height: AppDimensions.minTouchTarget,
    ),
    style: IconButton.styleFrom(
      foregroundColor: tone,
      backgroundColor: AppColors.surfaceRaised,
      side: BorderSide(
        color: onPressed == null ? AppColors.border : tone,
        width: AppDimensions.timetableIconButtonBorder,
      ),
    ),
    icon: Icon(icon),
  );
}
