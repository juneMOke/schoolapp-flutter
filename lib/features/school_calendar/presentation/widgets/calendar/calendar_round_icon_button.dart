import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Un geste en icône ronde de 48 dp, contour ardoise (maquette `CalIconBtn`) :
/// Imprimer et Dupliquer d'un calendrier, sous 600.
class CalendarRoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const CalendarRoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(AppDimensions.minTouchTarget),
      backgroundColor: AppColors.surfaceRaised,
      foregroundColor: AppColors.bleuArdoise,
      side: const BorderSide(
        color: AppColors.bleuArdoise,
        width: AppDimensions.calendarIconButtonStroke,
      ),
    ),
  );
}
