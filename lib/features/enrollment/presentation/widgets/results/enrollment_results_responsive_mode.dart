import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';

/// Résout le mode d'affichage en fonction de la largeur du conteneur.
class EnrollmentResultsResponsiveMode {
  const EnrollmentResultsResponsiveMode._();

  static EnrollmentListingViewMode resolve({
    required double containerWidth,
    required EnrollmentListingViewMode preferred,
  }) {
    // Un choix explicite (Liste ou Grille) est honoré à toute largeur, y
    // compris sur téléphone : la table bascule alors en rendu étroit 2 colonnes.
    if (preferred.isTable) {
      return EnrollmentListingViewMode.table;
    }
    if (preferred.isGrid) {
      return EnrollmentListingViewMode.grid;
    }

    // Mode auto : grille par défaut sous le seuil cartes, table au-dessus.
    if (containerWidth < AppBreakpoints.dataTableCardsMax) {
      return EnrollmentListingViewMode.grid;
    }
    return EnrollmentListingViewMode.table;
  }
}
