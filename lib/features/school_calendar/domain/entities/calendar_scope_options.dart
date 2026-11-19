import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';

/// Un cycle de l'école, proposé dans « Concerne » (CAL-R6).
class CalendarCycleOption extends Equatable {
  final String code;
  final String name;
  final PeriodRhythm? rhythm;

  const CalendarCycleOption({
    required this.code,
    required this.name,
    this.rhythm,
  });

  @override
  List<Object?> get props => [code, name, rhythm];
}

/// Un niveau de l'école, dans son cycle.
class CalendarLevelOption extends Equatable {
  final String cycleCode;
  final String code;
  final String name;

  const CalendarLevelOption({
    required this.cycleCode,
    required this.code,
    required this.name,
  });

  @override
  List<Object?> get props => [cycleCode, code, name];
}

/// Les cycles et niveaux de l'année en cours : « Concerne », les libellés des
/// portées, et les rythmes de périodes de l'école (A1).
class CalendarScopeOptions extends Equatable {
  final List<CalendarCycleOption> cycles;
  final List<CalendarLevelOption> levels;

  const CalendarScopeOptions({this.cycles = const [], this.levels = const []});

  /// Les rythmes de l'école, dans l'ordre du plus grand nombre de cycles.
  List<PeriodRhythm> get rhythms {
    final counts = <PeriodRhythm, int>{};
    for (final cycle in cycles) {
      final rhythm = cycle.rhythm;
      if (rhythm != null) counts[rhythm] = (counts[rhythm] ?? 0) + 1;
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  String? cycleName(String code) {
    for (final c in cycles) {
      if (c.code == code) return c.name;
    }
    return null;
  }

  String? levelName(String cycleCode, String code) {
    for (final l in levels) {
      if (l.cycleCode == cycleCode && l.code == code) return l.name;
    }
    return null;
  }

  @override
  List<Object?> get props => [cycles, levels];
}
