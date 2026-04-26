import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';

/// Carte d'etat partagée (loading / empty / erreur) avec action optionnelle.
class FinanceStateCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  const FinanceStateCard({
    super.key,
    required this.message,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FinanceMotion.medium,
      curve: FinanceMotion.outCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: AppDimensions.detailHeaderIconSize, color: accent),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: accent, height: 1.3),
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            child!,
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
