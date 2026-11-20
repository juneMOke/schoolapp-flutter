import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'actions de la consultation (EDT §4.6 C) : « Imprimer » (une
/// classe publiée ; icône de 48 dp sous 600, inactif hors ligne avec sa
/// raison), « Modifier » (sous `schedule.write`), la bascule Semaine | Jour.
class ConsultationActions extends StatelessWidget {
  final ClassTimetableMode mode;
  final ValueChanged<ClassTimetableMode> onMode;
  final bool published;
  final bool online;
  final bool narrow;
  final VoidCallback? onPrint;
  final VoidCallback? onEdit;

  const ConsultationActions({
    super.key,
    required this.mode,
    required this.onMode,
    required this.published,
    required this.online,
    required this.narrow,
    required this.onPrint,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (published)
          Tooltip(
            message: online
                ? l10n.classTimetablePrint
                : l10n.classTimetablePrintOffline,
            child: narrow
                ? IconButton.outlined(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print_outlined),
                  )
                : SecondaryButton(
                    label: l10n.classTimetablePrint,
                    icon: Icons.print_outlined,
                    fullWidth: false,
                    onPressed: onPrint,
                  ),
          ),
        if (onEdit case final edit?)
          PrimaryButton(
            label: l10n.classTimetableEdit,
            icon: Icons.edit_outlined,
            fullWidth: false,
            onPressed: edit,
          ),
        ClassTimetableModeSwitch(mode: mode, onMode: onMode),
      ],
    );
  }
}

/// La bascule Semaine | Jour, en consultation et dans le brouillon.
class ClassTimetableModeSwitch extends StatelessWidget {
  final ClassTimetableMode mode;
  final ValueChanged<ClassTimetableMode> onMode;

  const ClassTimetableModeSwitch({
    super.key,
    required this.mode,
    required this.onMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<ClassTimetableMode>(
      selected: mode,
      onSelected: onMode,
      options: [
        SegmentedTabOption(
          label: l10n.classTimetableWeek,
          value: ClassTimetableMode.week,
        ),
        SegmentedTabOption(
          label: l10n.classTimetableDay,
          value: ClassTimetableMode.day,
        ),
      ],
    );
  }
}
