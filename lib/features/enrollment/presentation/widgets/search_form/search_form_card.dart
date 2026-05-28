import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

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
      decoration: (showShadow ? AppElevation.surface3 : AppElevation.surface2)
          .copyWith(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
      padding: padding,
      child: child,
    );
  }
}
