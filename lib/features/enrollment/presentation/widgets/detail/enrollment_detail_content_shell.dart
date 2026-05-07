import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class EnrollmentDetailContentShell extends StatelessWidget {
  final Widget infoBar;
  final Widget child;

  const EnrollmentDetailContentShell({
    super.key,
    required this.infoBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.bleuArdoise.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -45,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  infoBar,
                  const SizedBox(height: AppSpacing.md),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
