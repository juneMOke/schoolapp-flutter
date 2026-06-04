import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';

/// Résout le mode d'affichage en fonction de la largeur du conteneur.
class EnrollmentResultsResponsiveMode {
  const EnrollmentResultsResponsiveMode._();

  static EnrollmentListingViewMode resolve({
    required double containerWidth,
    required EnrollmentListingViewMode preferred,
  }) {
    if (containerWidth < AppBreakpoints.dataTableCardsMax) {
      return EnrollmentListingViewMode.grid;
    }

    if (preferred.isGrid) {
      return EnrollmentListingViewMode.grid;
    }

    return EnrollmentListingViewMode.table;
  }
}
