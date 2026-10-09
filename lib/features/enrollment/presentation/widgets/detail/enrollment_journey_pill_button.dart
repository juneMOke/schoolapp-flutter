import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une action de dossier en pilule sur la barre sombre du parcours : contour
/// clair, ou vert savane pour un retour à la normale ([positive]).
class EnrollmentJourneyPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool positive;

  const EnrollmentJourneyPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.positive = false,
  });

  static const double _height = 40;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textOnDark,
        backgroundColor: positive
            ? AppColors.success.withValues(alpha: 0.35)
            : AppColors.textOnDark.withValues(alpha: 0.06),
        side: BorderSide(
          width: 1.5,
          color: positive
              ? AppColors.success.withValues(alpha: 0.6)
              : AppColors.textOnDark.withValues(alpha: 0.35),
        ),
        shape: const StadiumBorder(),
        textStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
    ),
  );
}
