import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une action de dossier en pilule sur la barre sombre du parcours : contour
/// clair, ou vert savane pour un retour à la normale ([positive]). Sous
/// [AppBreakpoints.enrollmentJourneyActionLabelsMin], l'icône seule, le
/// libellé en infobulle : la barre doit tenir sur une tablette en portrait.
class EnrollmentJourneyPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool positive;

  const EnrollmentJourneyPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.positive = false,
  });

  /// Alphas des surfaces « sur fond sombre ».
  static const double _fill = 0.06;
  static const double _outline = 0.35;
  static const double _positiveFill = 0.35;
  static const double _positiveOutline = 0.6;
  static const double _outlineWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width <
        AppBreakpoints.enrollmentJourneyActionLabelsMin;
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.textOnDark,
      backgroundColor: positive
          ? AppColors.success.withValues(alpha: _positiveFill)
          : AppColors.textOnDark.withValues(alpha: _fill),
      side: BorderSide(
        width: _outlineWidth,
        color: positive
            ? AppColors.success.withValues(alpha: _positiveOutline)
            : AppColors.textOnDark.withValues(alpha: _outline),
      ),
      shape: compact ? const CircleBorder() : const StadiumBorder(),
      textStyle: AppTypography.labelMedium,
      minimumSize: const Size.square(AppDimensions.minTouchTarget),
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
    final iconWidget = Icon(icon, size: AppDimensions.suspensionIconSize);
    if (compact) {
      return Tooltip(
        message: label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: Semantics(label: label, child: iconWidget),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: Text(label),
      style: style,
    );
  }
}
