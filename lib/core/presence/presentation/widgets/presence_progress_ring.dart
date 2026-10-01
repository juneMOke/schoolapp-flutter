import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'anneau de progression du jour : la part des agents pointés.
class PresenceProgressRing extends StatelessWidget {
  final int marked;
  final int total;

  const PresenceProgressRing({
    super.key,
    required this.marked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : marked / total;
    return SizedBox.square(
      dimension: AppDimensions.presenceMarkRingSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: AppDimensions.presenceMarkRingStroke,
              backgroundColor: AppColors.presenceMarkOnBannerFaint,
              color: ratio >= 1 ? AppColors.success : AppColors.orDoux,
            ),
          ),
          Text(
            '${(ratio * 100).round()}%',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.presenceMarkOnBanner,
            ),
          ),
        ],
      ),
    );
  }
}
