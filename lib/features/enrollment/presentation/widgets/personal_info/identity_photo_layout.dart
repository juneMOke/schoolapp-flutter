import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// L'étape « Identité » avec sa photo : l'emplacement en colonne fixe à
/// gauche de la grille, comme sur une carte d'élève ; au-dessus et centré
/// quand la grille n'aurait plus 552 dp.
class IdentityPhotoLayout extends StatelessWidget {
  final Widget? photo;
  final Widget fields;

  const IdentityPhotoLayout({
    super.key,
    required this.photo,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo == null) return fields;
    return LayoutBuilder(
      builder: (context, constraints) {
        final room =
            constraints.maxWidth -
            AppDimensions.photoSlotColumn -
            AppSpacing.xl;
        if (room < AppDimensions.photoSlotReflowBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: photo),
              const SizedBox(height: AppSpacing.xl),
              fields,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            photo,
            const SizedBox(width: AppSpacing.xl),
            Expanded(child: fields),
          ],
        );
      },
    );
  }
}
