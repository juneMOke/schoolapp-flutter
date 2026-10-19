import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Une carte bordée posée à côté d'une liste : la fiche ouverte, l'aperçu
/// ancré, la colonne de choix. Son contenu est découpé à ses coins.
class OutlinedPanel extends StatelessWidget {
  final Widget child;
  final Color? color;

  const OutlinedPanel({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadius.brCard,
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(borderRadius: AppRadius.brCard, child: child),
  );
}
