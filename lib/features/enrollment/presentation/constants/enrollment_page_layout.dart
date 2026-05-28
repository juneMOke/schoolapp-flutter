import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

class EnrollmentPageLayout {
  const EnrollmentPageLayout._();

  static const EdgeInsets contentPadding = EdgeInsets.zero;
  static const EdgeInsets firstRegistrationContentPaddingWithFab =
      EdgeInsets.only(bottom: AppDimensions.fabListBottomPadding);
  static const double sectionSpacing = AppDimensions.spacingS + 4;
  static const EdgeInsets loadingPadding = EdgeInsets.symmetric(
    vertical: AppDimensions.spacingXL + AppDimensions.spacingM,
  );
}
