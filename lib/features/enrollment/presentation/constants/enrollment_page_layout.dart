import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class EnrollmentPageLayout {
  const EnrollmentPageLayout._();

  static const EdgeInsets contentPadding = EdgeInsets.zero;
  static const EdgeInsets firstRegistrationContentPaddingWithFab =
      EdgeInsets.only(bottom: AppDimensions.fabListBottomPadding);
  // Carte recherche -> barre de resultats.
  static const double searchToSummarySpacing = AppSpacing.sectionGap;
  // Barre de resultats -> resultats.
  static const double summaryToResultsSpacing = AppSpacing.lg;
  static const EdgeInsets loadingPadding = EdgeInsets.symmetric(
    vertical: AppDimensions.spacingXL + AppDimensions.spacingM,
  );
}
