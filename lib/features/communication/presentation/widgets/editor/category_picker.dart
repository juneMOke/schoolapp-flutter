import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/choice_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Quatre catégories exclusives, Information par défaut.
class CategoryPicker extends StatelessWidget {
  final AnnouncementCategory value;
  final ValueChanged<AnnouncementCategory>? onChanged;

  const CategoryPicker({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.communicationCategoryLabel,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final category in AnnouncementCategory.values)
            ChoiceTile(
              label: l10n.categoryLabel(category),
              icon: categoryTone(category).icon,
              tone: categoryTone(category),
              selected: category == value,
              minHeight: AppDimensions.communicationChoiceMinHeight,
              onTap: onChanged == null ? null : () => onChanged!(category),
            ),
        ],
      ),
    );
  }
}
