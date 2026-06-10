import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class EnrollmentPageLayout {
  const EnrollmentPageLayout._();

  static const EdgeInsets contentPadding = EdgeInsets.zero;
  // Carte recherche -> barre de resultats.
  static const double searchToSummarySpacing = AppSpacing.sectionGap;
  // Barre de resultats -> resultats.
  static const double summaryToResultsSpacing = AppSpacing.lg;
  // Tableau -> action inline (bouton de creation, vue tablette).
  static const double resultsToFooterSpacing = AppSpacing.lg;
  static const EdgeInsets loadingPadding = EdgeInsets.symmetric(
    vertical: AppDimensions.spacingXL + AppDimensions.spacingM,
  );
}
