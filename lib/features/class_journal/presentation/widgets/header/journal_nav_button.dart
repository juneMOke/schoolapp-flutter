import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Un bouton ◀ / ▶ de l'en-tête : 40 dp, zone tactile étendue au minimum
/// Material, inactif aux bornes de l'année ([onPressed] nul).
class JournalNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const JournalNavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: AppDimensions.journalNavIconSize),
      color: AppColors.textPrimary,
      disabledColor: AppColors.borderStrong,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppDimensions.journalNavButton),
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brSm,
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
