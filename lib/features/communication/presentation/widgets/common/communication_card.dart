import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La carte élevée du module : filtres, liste, sections de l'éditeur.
class CommunicationCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CommunicationCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  /// Sans marge intérieure : la liste peint ses propres filets.
  const CommunicationCard.flush({super.key, required this.child})
    : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brLg,
      border: Border.all(color: AppColors.border),
      boxShadow: AppElevation.shadowCard,
    ),
    child: child,
  );
}
