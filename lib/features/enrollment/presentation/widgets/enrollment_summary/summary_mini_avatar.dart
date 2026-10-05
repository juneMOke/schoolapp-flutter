import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Pastille à initiales du Résumé — l'élève ou un parent. Pour l'élève,
/// [studentPhotoOf] montre sa photo à la place des initiales.
class SummaryMiniAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final double size;
  final String? studentPhotoOf;

  const SummaryMiniAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.size,
    this.studentPhotoOf,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(firstName, lastName);
    final fontSize = math.max(11.0, size * 0.30).toDouble();

    final initialsAvatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.bleuArdoise,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
    return PersonPhotoOr(
      personId: studentPhotoOf,
      size: size,
      fallback: initialsAvatar,
    );
  }

  String _initials(String first, String last) {
    final firstInitial = first.trim().isNotEmpty ? first.trim()[0] : '';
    final lastInitial = last.trim().isNotEmpty ? last.trim()[0] : '';
    final value = '$firstInitial$lastInitial'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }
}
