import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La photo de l'emplacement : un anneau blanc et un filet, autour de la
/// photo en brouillon ou de celle du registre.
class SlotPhoto extends StatelessWidget {
  final String studentId;
  final Uint8List? draft;
  final double size;

  const SlotPhoto({
    super.key,
    required this.studentId,
    this.draft,
    this.size = AppDimensions.photoSlotCircle,
  });

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    // L'anneau garde la proportion de l'emplacement (4 dp pour 128).
    final ring =
        size * AppDimensions.photoSlotRing / AppDimensions.photoSlotCircle;
    final inner = size - 2 * ring;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: draft != null
          ? ClipOval(
              child: Image.memory(
                draft,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => SizedBox.square(dimension: inner),
              ),
            )
          : PersonPhotoOr(
              personId: studentId,
              size: inner,
              fallback: SizedBox.square(dimension: inner),
            ),
    );
  }
}
