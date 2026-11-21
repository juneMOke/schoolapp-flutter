import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_icon_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'actions de la consultation (EDT §4.6 C) : la bascule Semaine |
/// Jour, la semaine affichée ([week]), puis « Imprimer » et « Copier… »
/// (secondaires) et « Modifier » (principal), poussés à droite. Sous 600,
/// chacun prend sa ligne : la bascule, la semaine, puis Imprimer en icône de
/// 48 dp, Copier et Modifier se partageant le reste. Sans le droit d'agir :
/// la bascule, la semaine et « Imprimer » seulement.
class ConsultationActions extends StatelessWidget {
  final ClassTimetableMode mode;
  final ValueChanged<ClassTimetableMode> onMode;
  final Widget week;
  final bool published;
  final bool online;
  final bool narrow;
  final VoidCallback? onPrint;

  /// « Copier… » et « Modifier » (I15, I7), sous `schedule.write` ; `null` :
  /// le bouton n'est pas montré.
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;

  const ConsultationActions({
    super.key,
    required this.mode,
    required this.onMode,
    required this.week,
    required this.published,
    required this.online,
    required this.narrow,
    required this.onPrint,
    this.onCopy,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final printTip = online
        ? l10n.classTimetablePrintIcon
        : l10n.classTimetablePrintOffline;
    final copy = onCopy;
    final edit = onEdit;
    final switcher = ClassTimetableModeSwitch(
      mode: mode,
      onMode: onMode,
      expand: narrow,
    );
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switcher,
          const SizedBox(height: AppSpacing.sm),
          week,
          if (published || copy != null || edit != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // L'icône seule porte son infobulle : le lecteur d'écran
                // l'annonce (« Imprimer », ou pourquoi c'est inactif).
                if (published)
                  TimetableIconButton(
                    icon: Icons.print_outlined,
                    tooltip: printTip,
                    onPressed: onPrint,
                  ),
                if (copy != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.classTimetableCopy,
                      icon: Icons.copy_all_outlined,
                      onPressed: copy,
                    ),
                  ),
                ],
                if (edit != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.classTimetableEdit,
                      icon: Icons.edit_outlined,
                      onPressed: edit,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }
    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (published)
          Tooltip(
            message: printTip,
            child: SecondaryButton(
              label: l10n.classTimetablePrint,
              icon: Icons.print_outlined,
              fullWidth: false,
              onPressed: onPrint,
            ),
          ),
        if (copy != null)
          SecondaryButton(
            label: l10n.classTimetableCopy,
            icon: Icons.copy_all_outlined,
            fullWidth: false,
            onPressed: copy,
          ),
        if (edit != null)
          PrimaryButton(
            label: l10n.classTimetableEdit,
            icon: Icons.edit_outlined,
            fullWidth: false,
            onPressed: edit,
          ),
      ],
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [switcher, week],
        ),
        actions,
      ],
    );
  }
}

/// La bascule Semaine | Jour de la consultation (icônes grille et liste).
class ClassTimetableModeSwitch extends StatelessWidget {
  final ClassTimetableMode mode;
  final ValueChanged<ClassTimetableMode> onMode;

  /// Toute la ligne, sous 600.
  final bool expand;

  const ClassTimetableModeSwitch({
    super.key,
    required this.mode,
    required this.onMode,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<ClassTimetableMode>(
      selected: mode,
      onSelected: onMode,
      expand: expand,
      options: [
        SegmentedTabOption(
          label: l10n.classTimetableWeek,
          value: ClassTimetableMode.week,
          icon: Icons.grid_view_rounded,
        ),
        SegmentedTabOption(
          label: l10n.classTimetableDay,
          value: ClassTimetableMode.day,
          icon: Icons.view_list_rounded,
        ),
      ],
    );
  }
}
