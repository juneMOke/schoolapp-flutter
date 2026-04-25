import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Carte de section partagée pour les écrans Finance (fond, bordure, ombre).
class FinanceSectionCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final bool withShadow;

  const FinanceSectionCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.backgroundColor,
    required this.borderColor,
    this.padding = const EdgeInsets.all(AppDimensions.detailCardPadding),
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors!,
              )
            : null,
        color: gradientColors == null
            ? (backgroundColor ?? AppColors.financeDetailCard)
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: borderColor),
        boxShadow: withShadow
            ? const [
                BoxShadow(
                  color: AppColors.financeDetailShadow,
                  blurRadius: AppDimensions.financeDetailCardShadowBlur,
                  offset: Offset(0, AppDimensions.financeDetailCardShadowOffsetY),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
