import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_actor.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// Un élément du calendrier : national (verrouillé) ou de l'école.
///
/// Les dates sont des jours civils ([CalendarDays]), bornes incluses
/// (CAL-R7). Une période porte en plus son rythme et ses ordres de période et
/// de sous-période : « P4 · 2e semestre » = période 2, sous-période 2.
class CalendarElement extends Equatable {
  /// Longueur maximale d'un intitulé (CAL-D8).
  static const titleMaxLength = 80;

  final String id;
  final CalendarSource source;
  final CalendarNature nature;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final CalendarScope scope;
  final String? note;
  final bool toVerify;
  final CalendarActor? createdBy;
  final PeriodRhythm? rhythm;
  final int? periodOrder;
  final int? subPeriodOrder;

  /// Un événement de l'école qui remplace un élément national : l'id de cet
  /// élément (`replacesItemId`), immuable une fois posé.
  final String? replaces;

  /// Un élément national que l'école peut remplacer (lu tel quel, jamais
  /// recalculé : `replaceable` du cadre).
  final bool replaceable;

  const CalendarElement({
    required this.id,
    required this.source,
    required this.nature,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.scope = const SchoolScope(),
    this.note,
    this.toVerify = false,
    this.createdBy,
    this.rhythm,
    this.periodOrder,
    this.subPeriodOrder,
    this.replaces,
    this.replaceable = false,
  });

  bool get isNational => source == CalendarSource.national;

  /// Remplace un élément national.
  bool get isReplacement => replaces != null;

  /// Durée en jours, bornes incluses.
  int get durationDays => CalendarDays.between(startDate, endDate) + 1;

  bool get isSingleDay => durationDays == 1;

  bool covers(DateTime day) => CalendarDays.within(day, startDate, endDate);

  bool overlaps(DateTime start, DateTime end) =>
      !CalendarDays.of(end).isBefore(CalendarDays.of(startDate)) &&
      !CalendarDays.of(start).isAfter(CalendarDays.of(endDate));

  /// Rang « P{n} » d'une sous-période : (période − 1) × 2 + sous-période.
  /// `null` hors des périodes, ou si les ordres manquent.
  int? get subPeriodRank {
    final period = periodOrder;
    final sub = subPeriodOrder;
    if (nature != CalendarNature.period || period == null || sub == null) {
      return null;
    }
    return (period - 1) * 2 + sub;
  }

  CalendarElement copyWith({
    String? title,
    CalendarNature? nature,
    DateTime? startDate,
    DateTime? endDate,
    CalendarScope? scope,
    String? note,
    bool clearNote = false,
    bool? toVerify,
  }) => CalendarElement(
    id: id,
    source: source,
    nature: nature ?? this.nature,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    scope: scope ?? this.scope,
    note: clearNote ? null : (note ?? this.note),
    toVerify: toVerify ?? this.toVerify,
    createdBy: createdBy,
    rhythm: rhythm,
    periodOrder: periodOrder,
    subPeriodOrder: subPeriodOrder,
    replaces: replaces,
    replaceable: replaceable,
  );

  /// Le remplacement de [national], avec son rythme et ses rangs de période.
  CalendarElement inheritingPeriodOf(CalendarElement national) => _with(
    replaces: replaces,
    rhythm: national.rhythm,
    periodOrder: national.periodOrder,
    subPeriodOrder: national.subPeriodOrder,
  );

  /// Le même élément, remplaçant [target].
  CalendarElement withReplaces(String target) => _with(
    replaces: target,
    rhythm: rhythm,
    periodOrder: periodOrder,
    subPeriodOrder: subPeriodOrder,
  );

  CalendarElement _with({
    required String? replaces,
    required PeriodRhythm? rhythm,
    required int? periodOrder,
    required int? subPeriodOrder,
  }) => CalendarElement(
    id: id,
    source: source,
    nature: nature,
    title: title,
    startDate: startDate,
    endDate: endDate,
    scope: scope,
    note: note,
    toVerify: toVerify,
    createdBy: createdBy,
    rhythm: rhythm,
    periodOrder: periodOrder,
    subPeriodOrder: subPeriodOrder,
    replaces: replaces,
    replaceable: replaceable,
  );

  @override
  List<Object?> get props => [
    id,
    source,
    nature,
    title,
    startDate,
    endDate,
    scope,
    note,
    toVerify,
    createdBy,
    rhythm,
    periodOrder,
    subPeriodOrder,
    replaces,
    replaceable,
  ];
}
