import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La carte élevée des deux écrans — strates de filtres, registre, sections
/// du tableau de bord.
class ExpenseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fond de la carte. Le défaut — blanc — est celui de tous ses appelants
  /// actuels ; la teinte est une **option** que chaque section déclare.
  final Color surfaceColor;

  /// Filet du cadre. Il suit la teinte quand il y en a une : sur un fond
  /// coloré, un contour resté gris détacherait mal la carte de la page.
  final Color borderColor;

  const ExpenseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingM),
    this.surfaceColor = AppColors.surfaceRaised,
    this.borderColor = AppColors.border,
  });

  /// Sans marge intérieure : le registre peint ses propres filets.
  ///
  /// Reste **neutre** : c'est une carte de liste, pas une section du tableau
  /// de bord.
  const ExpenseCard.flush({super.key, required this.child})
    : padding = EdgeInsets.zero,
      surfaceColor = AppColors.surfaceRaised,
      borderColor = AppColors.border;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: surfaceColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
    ),
    child: child,
  );
}
