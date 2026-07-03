import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État vide de l'emploi du temps (spec §9), via l'anatomie partagée
/// [EteeloEmptyResult]. Deux variantes : semaine ([day] nul → « Aucune séance
/// planifiée », l'emploi du temps est géré par la direction) ou jour ([day]
/// renseigné → « Aucun cours ce jour »). Aucune action (écran de consultation).
class ScheduleResultsEmptyState extends StatelessWidget {
  /// `null` → variante semaine ; renseigné → variante jour.
  final Weekday? day;

  const ScheduleResultsEmptyState({super.key, this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = day;

    if (selectedDay == null) {
      return EteeloEmptyResult(
        medallionIcon: Icons.calendar_month_outlined,
        label: l10n.scheduleEmpty,
        description: l10n.scheduleEmptyDescription,
        fullWidthCard: true,
      );
    }

    return EteeloEmptyResult(
      medallionIcon: Icons.event_busy_outlined,
      label: l10n.scheduleEmptyDayTitle,
      description: l10n.scheduleEmptyDayDescription(
        ScheduleWeekdayLabels.long(l10n, selectedDay),
      ),
      fullWidthCard: true,
    );
  }
}
