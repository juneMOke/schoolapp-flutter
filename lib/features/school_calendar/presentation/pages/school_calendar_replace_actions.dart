import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/pages/school_calendar_page_actions.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/event_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Remplacer un élément national, puis le rétablir (contrat du 2026-11-20).
/// Un remplacement est un événement de l'école comme un autre : même lot,
/// même dernier écrit gagne ; le supprimer ramène l'élément national.
extension SchoolCalendarReplaceActions on SchoolCalendarPageActions {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// O2 en mode remplacement : nature et portée de [national], figées.
  Future<void> replace(CalendarElement national) async {
    final state = cubit.state;
    final calendar = state.calendar;
    if (calendar == null) return;
    final saved = await EventFormDialog.show(
      context,
      EventFormDialog(
        newId: cubit.newEventId(),
        replacing: national,
        natures: {national.nature},
        scopes: state.scopes,
        yearStart: calendar.startDate,
        yearEnd: calendar.endDate,
        nationalElements: [
          for (final e in state.allElements)
            if (e.isNational || e.isReplacement) e,
        ],
      ),
    );
    if (!context.mounted || saved == null) return;
    final result = await cubit.saveEvent(saved);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
      (_) => AppSnackBar.showSuccess(
        context,
        _l10n.schoolCalendarSnackReplaced(CalendarLabels.dates(context, saved)),
      ),
    );
  }

  /// Supprimer [replacement] : l'élément national revient. Une période se
  /// rétablit avec les remplacements de sa période (la période et ses
  /// sous-périodes), dans le même lot : le serveur juge les périodes sur ce
  /// que le lot entier laisse, et refuserait une sous-période laissée hors de
  /// sa période.
  Future<void> restore(CalendarElement replacement) async {
    final national = cubit.state.nationalOf(replacement.replaces ?? '');
    final linked = replacement.nature == CalendarNature.period
        ? [
            for (final e in cubit.state.allElements)
              if (e.isReplacement &&
                  e.nature == CalendarNature.period &&
                  e.rhythm == replacement.rhythm &&
                  e.periodOrder == replacement.periodOrder)
                e,
          ]
        : [replacement];
    final restored = linked.isEmpty ? [replacement] : linked;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: _l10n.schoolCalendarRestoreTitle,
      message: [
        _l10n.schoolCalendarRestoreBody(
          national?.title ?? replacement.title,
          national == null ? '' : CalendarLabels.dates(context, national),
        ),
        if (restored.length > 1)
          _l10n.schoolCalendarRestoreLinked(restored.length - 1),
      ].join('\n\n'),
      confirmLabel: _l10n.schoolCalendarRestoreNational,
      cancelLabel: _l10n.schoolCalendarFormCancel,
    );
    if (!context.mounted || !confirmed) return;
    final result = await cubit.deleteEvents(restored);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
      (_) =>
          AppSnackBar.showSuccess(context, _l10n.schoolCalendarSnackRestored),
    );
  }
}
