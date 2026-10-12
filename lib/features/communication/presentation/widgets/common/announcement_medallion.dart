import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';

/// Le médaillon d'un communiqué : l'icône de sa catégorie, sur son fond.
class AnnouncementMedallion extends StatelessWidget {
  final AnnouncementCategory category;
  final double size;

  const AnnouncementMedallion({
    super.key,
    required this.category,
    this.size = AppDimensions.communicationMedallionSize,
  });

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(category);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(tone.icon, color: tone.ink, size: size / 2),
      ),
    );
  }
}
