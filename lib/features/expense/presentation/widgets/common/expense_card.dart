import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La carte élevée des deux écrans — strates de filtres, registre, sections
/// du tableau de bord.
class ExpenseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ExpenseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingM),
  });

  /// Sans marge intérieure : le registre peint ses propres filets.
  const ExpenseCard.flush({super.key, required this.child})
    : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
    ),
    child: child,
  );
}
