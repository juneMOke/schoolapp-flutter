import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/publish_calendar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_rights.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/pages/school_calendar_replace_actions.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/calendar_online_dialogs.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_sheet.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/event_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de l'écran, de la sur-couche à l'accusé (CAL-I11 à I17).
class SchoolCalendarPageActions {
  final BuildContext context;
  final SchoolCalendarCubit cubit;
  final CalendarRights rights;

  const SchoolCalendarPageActions(this.context, this.cubit, this.rights);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// O1, puis ce que l'utilisateur y choisit.
  Future<void> openElement(CalendarElement element) async {
    final choice = await showEteeloAdaptiveSheet<ElementDetailChoice>(
      context: context,
      maxWidth: AppDimensions.calendarDetailMaxWidth,
      builder: (_) => ElementDetailSheet(
        element: element,
        scopes: cubit.state.scopes,
        today: cubit.state.today,
        replaced: switch (element.replaces) {
          final id? => cubit.state.nationalOf(id),
          null => null,
        },
        // R13 : un calendrier archivé ne se touche plus, même depuis O1.
        canEdit:
            (element.isNational
                ? rights.canReplace(element.nature)
                : rights.canEdit(element.nature)) &&
            !(switch (cubit.state.calendar) {
              final c? => cubit.state.phaseOf(c).isReadOnly,
              null => true,
            }),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case ElementDetailChoice.edit:
        await edit(element: element);
      case ElementDetailChoice.delete:
        await (element.isReplacement ? restore(element) : delete(element));
      case ElementDetailChoice.replace:
        await replace(element);
      case ElementDetailChoice.verify:
        final result = await cubit.verify(element);
        if (!context.mounted) return;
        result.fold(
          (f) =>
              AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
          (_) => AppSnackBar.showSuccess(
            context,
            _l10n.schoolCalendarSnackVerified,
          ),
        );
    }
  }

  /// O2, vide (à la date du jour touché) ou pré-rempli.
  Future<void> edit({CalendarElement? element, DateTime? day}) async {
    final state = cubit.state;
    final calendar = state.calendar;
    if (calendar == null) return;
    // Un remplacement suit le cadre : si l'élément national a changé de
    // nature ou de portée à une republication, la modification les reprend.
    final national = switch (element?.replaces) {
      final id? => state.nationalOf(id),
      null => null,
    };
    final initial = national == null
        ? element
        : element?.copyWith(nature: national.nature, scope: national.scope);
    final saved = await EventFormDialog.show(
      context,
      EventFormDialog(
        newId: cubit.newEventId(),
        yearLabel: calendar.yearLabel,
        initial: initial,
        initialDay: day,
        natures: rights.writableNatures,
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
        element == null
            ? _l10n.schoolCalendarSnackAdded(
                CalendarLabels.dates(context, saved),
              )
            : _l10n.schoolCalendarSnackEdited,
      ),
    );
  }

  /// O6, puis la suppression (CAL-R12).
  Future<void> delete(CalendarElement element) async {
    final year = cubit.state.calendar?.yearLabel ?? '';
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: _l10n.schoolCalendarDeleteTitle,
      message: _l10n.schoolCalendarDeleteBody(
        element.title,
        CalendarLabels.dates(context, element),
        year,
      ),
      confirmLabel: _l10n.schoolCalendarDelete,
      cancelLabel: _l10n.schoolCalendarFormCancel,
      isDestructive: true,
    );
    if (!context.mounted || !confirmed) return;
    final result = await cubit.deleteEvent(element);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
      (_) => AppSnackBar.showSuccess(context, _l10n.schoolCalendarSnackDeleted),
    );
  }

  /// O4 : les années libres viennent du serveur (A5).
  Future<void> create() async {
    final years = await cubit.creatableYears();
    if (!context.mounted) return;
    final list = years.fold((f) {
      AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f));
      return null;
    }, (y) => y);
    if (list == null) return;
    final year = await EteeloFormDialog.show<String>(
      context,
      NewCalendarDialog(years: list),
    );
    if (!context.mounted || year == null) return;
    final result = await cubit.create(year);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
      (c) => AppSnackBar.showSuccess(
        context,
        _l10n.schoolCalendarSnackCreated(c.yearLabel),
      ),
    );
  }

  /// O3 : vers l'année suivante — du calendrier ouvert, ou de la carte
  /// [source] de la liste (menu « ⋮ »).
  Future<void> duplicate({SchoolCalendar? source}) async {
    final state = cubit.state;
    final calendar = source ?? state.calendar;
    final target = calendar?.nextYearLabel;
    if (calendar == null || target == null) return;
    final events = source == null
        ? state.events
        : (state.libraryEvents[source.id] ?? const []);
    // Le cadre de l'année visée, pour dire s'il est intégré ou attendu ;
    // inconnu si la question échoue (la duplication reste possible).
    final years = await cubit.creatableYears();
    if (!context.mounted) return;
    final framework = years.fold(
      (_) => null,
      (list) => [
        for (final y in list)
          if (y.yearLabel == target) y.framework,
      ].firstOrNull,
    );
    final natures = await EteeloFormDialog.show<List<CalendarNature>>(
      context,
      DuplicateCalendarDialog(
        sourceYear: calendar.yearLabel,
        targetYear: target,
        targetFramework: framework,
        sourceInForce: state.phaseOf(calendar) == CalendarPhase.inForce,
        eventCount: events
            .where(
              (r) => DuplicateCalendarDialog.eventNatures.contains(
                r.element.nature,
              ),
            )
            .length,
        windowCount: events
            .where((r) => r.element.nature == CalendarNature.assessment)
            .length,
      ),
    );
    if (!context.mounted || natures == null || natures.isEmpty) return;
    final result = await cubit.duplicate(natures, source: source);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
      (c) => AppSnackBar.showSuccess(
        context,
        _l10n.schoolCalendarSnackCreated(c.yearLabel),
      ),
    );
  }

  /// O5 : un seul envoi, même sur un double appui (le dialogue se ferme).
  Future<void> publish({required bool online, SchoolCalendar? source}) async {
    final state = cubit.state;
    final calendar = source ?? state.calendar;
    if (calendar == null) return;
    final summary = state.summaryOf(calendar);
    final all = summary.elements;
    final current = state.inForce;
    final ok = await PublishCalendarDialog.show(
      context,
      PublishCalendarDialog(
        relay: current == null || current.id == calendar.id
            ? null
            : (
                current: current.yearLabel,
                end: CalendarLabels.day(context, current.endDate),
                start: CalendarLabels.day(context, calendar.startDate),
              ),
        year: calendar.yearLabel,
        total: all.length,
        schoolCount: all.where((e) => !e.isNational).length,
        toVerify: summary.toVerifyCount,
        hasFramework: calendar.hasFramework,
        online: online,
        pending: summary.pendingCount > 0,
      ),
    );
    if (!context.mounted || !ok) return;
    final result = await cubit.publish(source: source);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(context, CalendarLabels.failure(_l10n, f)),
      (c) => AppSnackBar.showSuccess(
        context,
        _l10n.schoolCalendarSnackPublished(c.yearLabel),
      ),
    );
  }

  /// Un autre appareil a gagné : prévenir une fois (CAL-R16).
  Future<void> warnSuperseded() async {
    final superseded = await cubit.takeSuperseded();
    if (!context.mounted || superseded.isEmpty) return;
    AppSnackBar.showInfo(
      context,
      _l10n.schoolCalendarSupersededNotice(superseded.length),
    );
  }
}
