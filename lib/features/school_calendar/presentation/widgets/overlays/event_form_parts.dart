import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_event_validation.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les erreurs (bloquantes) et avertissements (non bloquants) de CAL-R7. Un
/// intitulé vide ne s'annonce pas : « Ajouter » reste simplement inactif.
class EventFormMessages extends StatelessWidget {
  final CalendarEventCheck? check;
  final DateTime yearStart;
  final DateTime yearEnd;

  const EventFormMessages({
    super.key,
    required this.check,
    required this.yearStart,
    required this.yearEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = this.check;
    if (check == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final error in check.errors)
          if (error != CalendarEventError.titleMissing)
            EteeloNotice.error(switch (error) {
              CalendarEventError.endBeforeStart =>
                l10n.schoolCalendarErrorEndBeforeStart,
              CalendarEventError.outOfYear => l10n.schoolCalendarErrorOutOfYear(
                CalendarLabels.day(context, yearStart),
                CalendarLabels.day(context, yearEnd),
              ),
              _ => l10n.schoolCalendarErrorTitleTooLong,
            }),
        for (final warning in check.warnings)
          EteeloNotice.warning(
            warning.isBreakOverlap
                ? l10n.schoolCalendarWarnOverlap(
                    warning.overlapped.title,
                    CalendarLabels.dates(context, warning.overlapped),
                  )
                : l10n.schoolCalendarWarnExam(warning.overlapped.title),
          ),
      ],
    );
  }
}

/// « Concerne » (CAL-R6) : l'école, un cycle, ou un niveau d'un cycle. Sans
/// [onChanged], le champ est en lecture seule (un remplacement garde la portée
/// de l'élément national, rythme ou niveaux du catalogue compris).
class EventScopeSelect extends StatelessWidget {
  final CalendarScope scope;
  final CalendarScopeOptions options;
  final ValueChanged<CalendarScope>? onChanged;

  const EventScopeSelect({
    super.key,
    required this.scope,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final change = onChanged;
    final items = <EteeloSelectItem<String>>[
      EteeloSelectItem(
        value: const SchoolScope().wire,
        label: l10n.schoolCalendarScopeSchool,
      ),
      for (final cycle in options.cycles) ...[
        EteeloSelectItem(
          value: CycleScope(cycle.code).wire,
          label: l10n.schoolCalendarScopeCycle(cycle.name),
        ),
        for (final level in options.levels)
          if (level.cycleCode == cycle.code)
            EteeloSelectItem(
              value: LevelScope(
                cycleCode: cycle.code,
                levelCode: level.code,
              ).wire,
              label: l10n.schoolCalendarScopeLevel(level.name),
            ),
      ],
    ];
    // Une portée hors du choix de l'école (rythme, niveaux du catalogue, ou
    // un cycle que l'école n'a plus) : celle de l'élément national remplacé,
    // montrée telle quelle.
    if (items.every((item) => item.value != scope.wire)) {
      items.insert(
        0,
        EteeloSelectItem(
          value: scope.wire,
          label: CalendarLabels.scope(l10n, scope, options),
        ),
      );
    }
    return EteeloSelectInput<String>(
      label: l10n.schoolCalendarConcerns,
      value: scope.wire,
      readOnly: change == null,
      onChanged: (v) => change?.call(CalendarScope.parse(v)),
      items: items,
    );
  }
}

/// En tête d'un remplacement : la nature, figée, et ce que fait le geste.
class EventReplacementNotice extends StatelessWidget {
  final CalendarNature nature;

  const EventReplacementNotice({super.key, required this.nature});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventFieldLabel(l10n.schoolCalendarFormNature),
        Align(
          alignment: Alignment.centerLeft,
          child: EteeloFilterChip(
            iconMedallion: true,
            label: CalendarLabels.nature(l10n, nature),
            selected: true,
            color: nature.tone.tone,
            soft: nature.tone.soft,
            ink: nature.tone.ink,
            icon: nature.tone.icon,
            onTap: null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EteeloNotice.warning(l10n.schoolCalendarReplaceNotice),
      ],
    );
  }
}

/// La nature d'un événement : une puce par nature permise, ou, pour un
/// remplacement ([locked]), celle de l'élément national, figée.
class EventNatureChoice extends StatelessWidget {
  final CalendarNature nature;
  final Set<CalendarNature> natures;
  final bool locked;
  final ValueChanged<CalendarNature> onChanged;

  const EventNatureChoice({
    super.key,
    required this.nature,
    required this.natures,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) return EventReplacementNotice(nature: nature);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventFieldLabel(l10n.schoolCalendarFormNature),
        // L'interligne est dans la zone de toucher des puces (48 dp).
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final n in CalendarNature.values)
              if (natures.contains(n))
                EteeloFilterChip(
                  padTapTarget: true,
                  iconMedallion: true,
                  label: CalendarLabels.nature(l10n, n),
                  selected: nature == n,
                  color: n.tone.tone,
                  soft: n.tone.soft,
                  ink: n.tone.ink,
                  icon: n.tone.icon,
                  onTap: () => onChanged(n),
                ),
          ],
        ),
      ],
    );
  }
}

/// Le libellé d'un champ composé à la main, au style des champs du socle ;
/// [hint] le suit en plus discret (« (facultatif) »).
class EventFieldLabel extends StatelessWidget {
  final String label;
  final String? hint;

  const EventFieldLabel(this.label, {super.key, this.hint});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
    child: Text.rich(
      TextSpan(
        text: label,
        children: [
          if (hint case final more?)
            TextSpan(
              text: ' $more',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
      style: AppTypography.labelFormLarge.copyWith(
        color: AppColors.textPrimary,
        height: 1.3,
      ),
    ),
  );
}

/// « Note (facultatif) » : le libellé en deux tons de la maquette.
class EventNoteField extends StatelessWidget {
  final TextEditingController controller;

  const EventNoteField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: EventFieldLabel(
            l10n.schoolCalendarFormNoteLabel,
            hint: l10n.schoolCalendarFormOptional,
          ),
        ),
        EteeloTextInput(
          controller: controller,
          label: l10n.schoolCalendarFormNote,
          hideLabel: true,
          keyboardType: EteeloTextInputType.multiline,
          minLines: 2,
          maxLines: 4,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              CalendarEventValidation.noteMaxLength,
            ),
          ],
        ),
      ],
    );
  }
}
