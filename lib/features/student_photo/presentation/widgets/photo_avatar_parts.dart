import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/helpers/initials_helper.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'avatar et son badge caméra terre cuite, Ø max(20, 0,42 × Ø) ; un contour
/// pointillé or quand il n'y a pas encore de photo.
class PhotoAvatarBadged extends StatelessWidget {
  final Widget avatar;
  final bool dashed;

  const PhotoAvatarBadged({
    super.key,
    required this.avatar,
    required this.dashed,
  });

  @override
  Widget build(BuildContext context) {
    const size = AppDimensions.photoHeaderAvatar;
    final badge = math.max(
      AppDimensions.photoHeaderBadgeMin,
      AppDimensions.photoHeaderBadgeRatio * size,
    );
    const outline = size + 2 * AppDimensions.photoHeaderOutlineGap;
    return SizedBox.square(
      dimension: outline,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (dashed)
            Container(
              width: outline,
              height: outline,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.orDoux.withValues(alpha: 0.75),
                  width: AppDimensions.photoHeaderOutlineStroke,
                ),
              ),
            ),
          avatar,
          Positioned(
            right: -AppDimensions.photoHeaderOutlineStroke,
            bottom: -AppDimensions.photoHeaderOutlineStroke,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: AppColors.terreCuite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bleuProfond,
                  width: AppDimensions.photoHeaderBadgeBorder,
                ),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: badge * 0.5,
                color: AppColors.onPhotoCapture,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les initiales sur fond blanc translucide, comme l'avatar des fiches.
class PhotoHeaderInitials extends StatelessWidget {
  final String firstName;
  final String lastName;

  const PhotoHeaderInitials({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.photoHeaderAvatar,
      height: AppDimensions.photoHeaderAvatar,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.onPhotoCaptureVeil,
        shape: BoxShape.circle,
      ),
      child: Text(
        InitialsHelper.initialsFrom(firstName, lastName),
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.onPhotoCapture,
        ),
      ),
    );
  }
}
