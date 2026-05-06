import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class SearchFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showShadow;

  const SearchFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingM),
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: AppDimensions.spacingM,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
