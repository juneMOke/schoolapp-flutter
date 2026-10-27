import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Le médaillon d'une tête de fiche : un carré blanc arrondi, l'icône dans la
/// teinte de ce qu'il annonce (le type d'une dépense, un rapport validé).
/// Posé sur un fond teinté, il en détache le repère.
class EteeloIconMedallion extends StatelessWidget {
  final IconData icon;
  final Color color;

  const EteeloIconMedallion({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.medallionSize,
    height: AppDimensions.medallionSize,
    decoration: const BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brMd,
    ),
    child: Icon(icon, size: AppDimensions.medallionIconSize, color: color),
  );
}
