import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_page_hero.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListPageHeader extends StatelessWidget {
  const ClassesListPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClassesPageHero(
      title: l10n.classesListHeroTitle,
      subtitle: l10n.classesListHeroSubtitle,
      icon: Icons.groups_rounded,
      chips: [
        ClassesPageHeroChipData(
          icon: Icons.filter_alt_outlined,
          label: l10n.classesListHeroFilterChip,
        ),
        ClassesPageHeroChipData(
          icon: Icons.meeting_room_outlined,
          label: l10n.classesListHeroClassroomChip,
        ),
      ],
    );
  }
}
