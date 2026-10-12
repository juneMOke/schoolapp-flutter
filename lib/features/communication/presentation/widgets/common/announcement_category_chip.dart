import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La pastille d'une catégorie, dans sa teinte.
class AnnouncementCategoryChip extends StatelessWidget {
  final AnnouncementCategory category;

  const AnnouncementCategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(category);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        AppLocalizations.of(context)!.categoryLabel(category),
        style: AppTypography.labelSmall.copyWith(color: tone.ink),
      ),
    );
  }
}
