import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Le décor sombre de la prise de vue, partagé par la modale et la séance.
abstract final class PhotoCaptureDecor {
  /// Le dégradé du bleu profond, incliné à 160° comme sur la maquette.
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment(-0.34, -1),
    end: Alignment(0.34, 1),
    colors: [AppColors.photoCaptureTop, AppColors.photoCaptureBottom],
  );

  /// L'ombre du panneau flottant (0 24 64, 35 %).
  static const List<BoxShadow> panelShadow = [
    BoxShadow(
      color: AppColors.photoPanelShadow,
      blurRadius: 64,
      offset: Offset(0, 24),
    ),
  ];

  /// L'échelle de départ de l'entrée du panneau (0,9 → 1).
  static const double entryScale = 0.9;
}
