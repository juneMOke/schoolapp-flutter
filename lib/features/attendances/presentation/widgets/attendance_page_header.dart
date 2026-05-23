import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_page_hero.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendancePageHeader extends StatelessWidget {
  const AttendancePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClassesPageHero(
      title: l10n.attendanceHeroTitle,
      subtitle: l10n.attendanceHeroSubtitle,
      icon: Icons.fact_check_outlined,
      chips: [
        ClassesPageHeroChipData(
          icon: Icons.class_outlined,
          label: l10n.attendanceHeroChipClass,
        ),
        ClassesPageHeroChipData(
          icon: Icons.event_outlined,
          label: l10n.attendanceHeroChipDate,
        ),
      ],
    );
  }
}
