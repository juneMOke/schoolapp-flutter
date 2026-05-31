import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

class EnrollmentStatsLoadingView extends StatelessWidget {
  const EnrollmentStatsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
