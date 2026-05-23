import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_page_hero.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationPageHeader extends StatelessWidget {
  const ClassesOrganisationPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClassesPageHero(
      title: l10n.classesOrganisationHeroTitle,
      subtitle: l10n.classesOrganisationHeroSubtitle,
      icon: Icons.class_outlined,
      titleColor: AppColors.bleuArdoise,
      chips: [
        ClassesPageHeroChipData(
          icon: Icons.grid_view_rounded,
          label: l10n.classesOrganisationSplitInfo,
        ),
        ClassesPageHeroChipData(
          icon: Icons.list_alt_rounded,
          label: l10n.classesOrganisationNonSplitInfo,
        ),
      ],
    );
  }
}
