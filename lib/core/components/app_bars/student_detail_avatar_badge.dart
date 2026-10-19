import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_avatar.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Avatar rond à initiales sur fond blanc translucide — ou la photo de
/// l'élève, quand il en a une.
class StudentDetailAvatarBadge extends StatelessWidget {
  final String initials;
  final double size;
  final String? studentId;

  const StudentDetailAvatarBadge({
    super.key,
    required this.initials,
    required this.size,
    this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.textOnDark,
          fontSize: 15,
        ),
      ),
    );
    return PersonPhotoOr(personId: studentId, size: size, fallback: badge);
  }
}
