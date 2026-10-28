import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le renvoi d'une carte du tableau de bord vers l'écran où l'on agit :
/// « Gérer → », la flèche après le texte, en bleu de lecture.
class PayrollDashboardLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PayrollDashboardLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    iconAlignment: IconAlignment.end,
    icon: const Icon(
      Icons.arrow_forward,
      size: AppDimensions.detailMiniIconSize,
    ),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: DashboardSense.attendu,
      textStyle: AppTypography.titleSmall,
      minimumSize: const Size(0, AppDimensions.minTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    ),
  );
}
