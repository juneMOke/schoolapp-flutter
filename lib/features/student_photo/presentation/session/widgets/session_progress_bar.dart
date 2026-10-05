import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// 4 dp, du terre cuite à l'or : la part des élèves traités.
class SessionProgressBar extends StatelessWidget {
  final double value;

  const SessionProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: SizedBox(
        height: AppDimensions.photoSessionProgressBar,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.onPhotoCaptureVeil),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.terreCuite, AppColors.orDoux],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
