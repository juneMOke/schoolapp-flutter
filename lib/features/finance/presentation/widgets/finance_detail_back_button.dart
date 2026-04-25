import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class FinanceDetailBackButton extends StatelessWidget {
  final String label;
  final String fallbackRoute;

  const FinanceDetailBackButton({
    super.key,
    required this.label,
    required this.fallbackRoute,
  });

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.financeDetailAccent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        ),
      ),
      onPressed: () => _goBack(context),
      icon: const Icon(Icons.arrow_back_outlined),
      label: Text(label, style: AppTextStyles.action),
    );
  }
}
