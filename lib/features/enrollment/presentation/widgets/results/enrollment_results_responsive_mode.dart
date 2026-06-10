import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';

/// Résout le mode d'affichage effectif à partir du mode préféré.
class EnrollmentResultsResponsiveMode {
  const EnrollmentResultsResponsiveMode._();

  static EnrollmentListingViewMode resolve({
    required EnrollmentListingViewMode preferred,
  }) {
    // Choix explicite Grille honoré ; sinon (auto = défaut) → TABLE à toute
    // largeur, y compris mobile (la table a un rendu étroit 2 colonnes adapté
    // au téléphone). La grille reste accessible via le basculeur de vue.
    if (preferred.isGrid) {
      return EnrollmentListingViewMode.grid;
    }
    return EnrollmentListingViewMode.table;
  }
}
