import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Feuille sur un écran étroit, modale centrée sur un écran large.
///
/// Une feuille ancrée en bas d'un écran de 1 920 dp s'étire sur toute sa
/// largeur, loin du regard et de la souris. Arbitré à l'OUVERTURE, comme le
/// sélecteur (même seuil) : tourner la tablette ne transforme pas la modale
/// en cours.
///
/// Le contenu est le même dans les deux formes ; il défile lui-même s'il est
/// long (la modale est bornée en hauteur).
Future<T?> showEteeloAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width < AppBreakpoints.adaptiveSheetDialogMin) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.card),
      ),
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.adaptiveSheetDialogMaxWidth,
          maxHeight: size.height * AppDimensions.adaptiveSheetDialogHeightRatio,
        ),
        child: builder(dialogContext),
      ),
    ),
  );
}
