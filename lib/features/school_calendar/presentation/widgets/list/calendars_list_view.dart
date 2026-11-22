import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendar_card.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_list_header.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_section.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/current_year_hero.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/upcoming_appointments.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La liste des calendriers (CAL §4.1, niveau 1 ; maquette `CalList`) :
/// l'en-tête, l'année en vigueur dans son bandeau, les prochains
/// rendez-vous, puis « À venir » et les « Archives », repliées (A1).
class CalendarsListView extends StatefulWidget {
  final SchoolCalendarState state;

  /// « Nouveau calendrier » : direction, en ligne.
  final bool canCreate;

  /// « Dupliquer pour … » dans le menu des cartes : direction, en ligne.
  final bool canDuplicate;
  final bool online;
  final VoidCallback onCreate;
  final ValueChanged<String> onOpen;
  final ValueChanged<SchoolCalendar>? onDuplicate;

  /// Le compte voit les brouillons (un droit d'écriture, K10) : sans lui, le
  /// brouillon de l'année en cours ne prend pas le bandeau.
  final bool canSeeDrafts;

  /// « Publier » sur le bandeau du brouillon : droit de publier, en ligne.
  final bool canPublish;
  final ValueChanged<SchoolCalendar>? onPublish;

  const CalendarsListView({
    super.key,
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onOpen,
    this.canDuplicate = false,
    this.online = true,
    this.onDuplicate,
    this.canSeeDrafts = false,
    this.canPublish = false,
    this.onPublish,
  });

  @override
  State<CalendarsListView> createState() => _CalendarsListViewState();
}

class _CalendarsListViewState extends State<CalendarsListView> {
  bool _showArchives = false;

  SchoolCalendarState get _state => widget.state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calendars = _state.library.calendars;
    final inForce = _state.inForce;
    // Sans année en vigueur, le brouillon de l'année en cours prend le
    // bandeau (décision B), pour qui voit les brouillons.
    final current =
        inForce ?? (widget.canSeeDrafts ? _state.currentDraft : null);
    bool isArchive(SchoolCalendar c) =>
        _state.phaseOf(c) == CalendarPhase.archived ||
        _state.phaseOf(c) == CalendarPhase.ended;
    // Le calendrier du bandeau ne revient pas en carte.
    final upcoming = [
      for (final c in calendars)
        if (c != current && !isArchive(c)) c,
    ]..sort((a, b) => a.yearLabel.compareTo(b.yearLabel));
    final archived = [
      for (final c in calendars)
        if (c != current && isArchive(c)) c,
    ]..sort((a, b) => b.yearLabel.compareTo(a.yearLabel));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarsListHeader(
          onCreate: widget.canCreate && calendars.isNotEmpty
              ? widget.onCreate
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!widget.online) EteeloNotice.warning(l10n.schoolCalendarOffline),
        if (calendars.isEmpty)
          _empty(l10n)
        else ...[
          if (current != null) ..._current(current),
          if (upcoming.isNotEmpty) ...[
            CalendarsSectionTitle(
              title: l10n.schoolCalendarFutureSection,
              count: upcoming.length,
            ),
            const SizedBox(height: AppSpacing.sm),
            CalendarsGrid(children: [for (final c in upcoming) _card(c)]),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (archived.isNotEmpty) ...[
            CalendarsSectionTitle(
              title: l10n.schoolCalendarArchiveSection,
              count: archived.length,
              trailing: CalendarsSectionToggle(
                expanded: _showArchives,
                showLabel: l10n.schoolCalendarShow,
                hideLabel: l10n.schoolCalendarHide,
                onPressed: () => setState(() => _showArchives = !_showArchives),
              ),
            ),
            if (_showArchives) ...[
              const SizedBox(height: AppSpacing.sm),
              CalendarsGrid(children: [for (final c in archived) _card(c)]),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
          if (inForce != null && _duplicable(inForce))
            Text(
              l10n.schoolCalendarTip(inForce.yearLabel),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ],
    );
  }

  List<Widget> _current(SchoolCalendar current) {
    final elements = _state.summaryOf(current).elements;
    final phase = _state.phaseOf(current);
    final publish = widget.onPublish;
    void open() => widget.onOpen(current.yearLabel);
    return [
      CurrentYearHero(
        calendar: current,
        elements: elements,
        today: _state.today,
        rhythm: _state.effectiveRhythm,
        onOpen: open,
        phase: phase,
        onPublish:
            phase == CalendarPhase.draft && widget.canPublish && publish != null
            ? () => publish(current)
            : null,
      ),
      const SizedBox(height: AppSpacing.lg),
      if (UpcomingAppointments.pick(elements, _state.today).isNotEmpty) ...[
        UpcomingAppointments(
          yearLabel: current.yearLabel,
          elements: elements,
          today: _state.today,
          onOpen: open,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ];
  }

  /// Dupliquer n'est offert que si l'année suivante n'a pas de calendrier.
  bool _duplicable(SchoolCalendar c) {
    if (!widget.canDuplicate || widget.onDuplicate == null) return false;
    final next = c.nextYearLabel;
    return next != null &&
        _state.library.calendars.every((x) => x.yearLabel != next);
  }

  Widget _card(SchoolCalendar c) {
    final duplicate = widget.onDuplicate;
    return CalendarCard(
      calendar: c,
      phase: _state.phaseOf(c),
      summary: _state.summaryOf(c),
      today: _state.today,
      onOpen: () => widget.onOpen(c.yearLabel),
      onDuplicate: duplicate != null && _duplicable(c)
          ? () => duplicate(c)
          : null,
    );
  }

  Widget _empty(AppLocalizations l10n) {
    // L'année proposée : un cadre national publié qui n'a pas encore de
    // calendrier (le plus récent) ; sinon le libellé générique.
    final frameworks = [..._state.library.frameworks]
      ..sort((a, b) => b.yearLabel.compareTo(a.yearLabel));
    final year = frameworks.isEmpty ? null : frameworks.first.yearLabel;
    return EteeloEmptyResult(
      label: l10n.schoolCalendarEmptyTitle,
      description: l10n.schoolCalendarEmptyBody,
      medallionIcon: Icons.calendar_today_outlined,
      fullWidthCard: true,
      primaryAction: widget.canCreate
          ? PrimaryButton(
              label: year == null
                  ? l10n.schoolCalendarNew
                  : l10n.schoolCalendarEmptyCreate(year),
              icon: Icons.add_rounded,
              fullWidth: false,
              onPressed: widget.onCreate,
            )
          : null,
    );
  }
}
