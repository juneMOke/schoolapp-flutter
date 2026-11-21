import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_phase_rule.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/calendar_summary.dart';

enum SchoolCalendarStatus { loading, ready, failure }

/// Les trois vues d'un calendrier (CAL-I2) ; Mois par défaut.
enum CalendarView { year, month, list }

/// Le filtre de source (CAL-I9).
enum CalendarSourceFilter { all, national, school }

class SchoolCalendarState extends Equatable {
  final SchoolCalendarStatus status;
  final Failure? failure;
  final CalendarLibrary library;
  final CalendarScopeOptions scopes;

  /// Le calendrier ouvert, par son année (l'adresse le retient) ; `null` :
  /// la liste des calendriers.
  final String? openYear;
  final List<SchoolEventRecord> events;
  final int pendingCount;

  /// Les événements de l'école de chaque calendrier, par son id : les cartes
  /// et le bandeau de la liste en comptent les éléments (CAL D5).
  final Map<String, List<SchoolEventRecord>> libraryEvents;

  /// Les gestes encore sur l'appareil, par calendrier.
  final Map<String, int> libraryPending;

  final CalendarView view;

  /// Le mois affiché, par son premier jour.
  final DateTime? month;
  final DateTime? selectedDay;
  final Set<CalendarNature> hiddenNatures;
  final CalendarSourceFilter source;
  final bool verifyOnly;

  /// Le jeu de périodes montré quand l'école a les deux rythmes (A1).
  final PeriodRhythm? rhythm;

  /// Le jour de l'école, recalculé à chaque chargement.
  final DateTime today;

  const SchoolCalendarState({
    required this.today,
    this.status = SchoolCalendarStatus.loading,
    this.failure,
    this.library = const CalendarLibrary(calendars: [], frameworks: []),
    this.scopes = const CalendarScopeOptions(),
    this.openYear,
    this.events = const [],
    this.pendingCount = 0,
    this.libraryEvents = const {},
    this.libraryPending = const {},
    this.view = CalendarView.month,
    this.month,
    this.selectedDay,
    this.hiddenNatures = const {},
    this.source = CalendarSourceFilter.all,
    this.verifyOnly = false,
    this.rhythm,
  });

  SchoolCalendar? get calendar {
    for (final c in library.calendars) {
      if (c.yearLabel == openYear) return c;
    }
    return null;
  }

  CalendarPhase phaseOf(SchoolCalendar c) => CalendarPhaseRule.compute(
    status: c.status,
    startDate: c.startDate,
    endDate: c.endDate,
    today: today,
    nextFrameworkStartDate: library.nextFrameworkStartOf(c),
  );

  /// Le calendrier en vigueur aujourd'hui, s'il y en a un.
  SchoolCalendar? get inForce {
    for (final c in library.calendars) {
      if (phaseOf(c) == CalendarPhase.inForce) return c;
    }
    return null;
  }

  /// Le rythme effectif : le choix, sinon celui du plus grand nombre de
  /// cycles ; `null` si l'école n'en déclare aucun.
  PeriodRhythm? get effectiveRhythm {
    final rhythms = scopes.rhythms;
    if (rhythm != null && rhythms.contains(rhythm)) return rhythm;
    return rhythms.isEmpty ? null : rhythms.first;
  }

  /// Tous les éléments du calendrier ouvert (`resolveCalendarElements`).
  List<CalendarElement> get allElements {
    final c = calendar;
    return c == null ? const [] : summaryOf(c).elements;
  }

  /// Ce que la liste dit d'un calendrier : le calendrier ouvert se lit sur
  /// [events], les autres sur [libraryEvents].
  CalendarSummary summaryOf(SchoolCalendar c) {
    final isOpen = c.yearLabel == openYear;
    return CalendarSummary(
      elements: resolveCalendarElements(
        national: library.frameworkOf(c.yearLabel)?.items ?? const [],
        events: isOpen ? events : (libraryEvents[c.id] ?? const []),
        rhythm: effectiveRhythm,
      ),
      pendingCount: isOpen ? pendingCount : (libraryPending[c.id] ?? 0),
    );
  }

  /// L'élément national du cadre de l'année, par son id.
  CalendarElement? nationalOf(String id) {
    final c = calendar;
    if (c == null) return null;
    for (final item in library.frameworkOf(c.yearLabel)?.items ?? const []) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Ce que montrent les vues, après légende, source et « à vérifier ».
  List<CalendarElement> get visibleElements => [
    for (final e in allElements)
      if (!hiddenNatures.contains(e.nature) &&
          (source == CalendarSourceFilter.all ||
              (source == CalendarSourceFilter.national) == e.isNational) &&
          (!verifyOnly || e.toVerify))
        e,
  ];

  SchoolEventRecord? recordOf(String elementId) {
    for (final r in events) {
      if (r.element.id == elementId) return r;
    }
    return null;
  }

  int get toVerifyCount => events.where((r) => r.element.toVerify).length;

  SchoolCalendarState copyWith({
    SchoolCalendarStatus? status,
    Failure? failure,
    CalendarLibrary? library,
    CalendarScopeOptions? scopes,
    String? openYear,
    bool closeCalendar = false,
    List<SchoolEventRecord>? events,
    int? pendingCount,
    Map<String, List<SchoolEventRecord>>? libraryEvents,
    Map<String, int>? libraryPending,
    CalendarView? view,
    DateTime? month,
    DateTime? selectedDay,
    bool clearSelectedDay = false,
    Set<CalendarNature>? hiddenNatures,
    CalendarSourceFilter? source,
    bool? verifyOnly,
    PeriodRhythm? rhythm,
    DateTime? today,
  }) => SchoolCalendarState(
    status: status ?? this.status,
    failure: failure,
    library: library ?? this.library,
    scopes: scopes ?? this.scopes,
    openYear: closeCalendar ? null : (openYear ?? this.openYear),
    events: events ?? this.events,
    pendingCount: pendingCount ?? this.pendingCount,
    libraryEvents: libraryEvents ?? this.libraryEvents,
    libraryPending: libraryPending ?? this.libraryPending,
    view: view ?? this.view,
    month: month ?? this.month,
    selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
    hiddenNatures: hiddenNatures ?? this.hiddenNatures,
    source: source ?? this.source,
    verifyOnly: verifyOnly ?? this.verifyOnly,
    rhythm: rhythm ?? this.rhythm,
    today: today ?? this.today,
  );

  @override
  List<Object?> get props => [
    status,
    failure,
    library.calendars,
    library.frameworks,
    scopes,
    openYear,
    events,
    pendingCount,
    libraryEvents,
    libraryPending,
    view,
    month,
    selectedDay,
    hiddenNatures,
    source,
    verifyOnly,
    rhythm,
    today,
  ];
}
