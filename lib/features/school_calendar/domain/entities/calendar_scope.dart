import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';

/// « Concerne » d'un élément, toujours **par code** (K7, A2).
///
/// - École : `SCHOOL` ;
/// - cycle : `CYCLE:<code du cycle>` ;
/// - niveau : `LEVEL:<code du cycle>/<code du niveau>` — un code de niveau
///   n'est unique que dans son cycle (V91) ;
/// - national seulement : `RHYTHM:<SEMESTER|TRIMESTER>` et
///   `CATALOG_LEVEL:<code>[,<code>…]` — jamais un niveau hors catalogue.
///
/// Une forme inconnue est gardée telle quelle ([UnknownScope]) : elle ne
/// concerne aucune classe, et l'écran l'affiche sans planter.
sealed class CalendarScope extends Equatable {
  const CalendarScope();

  static const _cycle = 'CYCLE:';
  static const _level = 'LEVEL:';
  static const _rhythm = 'RHYTHM:';
  static const _catalog = 'CATALOG_LEVEL:';

  static CalendarScope parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == SchoolScope.wireValue) {
      return const SchoolScope();
    }
    if (value.startsWith(_cycle)) {
      final code = value.substring(_cycle.length);
      return code.isEmpty ? UnknownScope(value) : CycleScope(code);
    }
    if (value.startsWith(_level)) {
      final parts = value.substring(_level.length).split('/');
      if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return LevelScope(cycleCode: parts[0], levelCode: parts[1]);
      }
      return UnknownScope(value);
    }
    if (value.startsWith(_rhythm)) {
      final rhythm = PeriodRhythm.fromWire(value.substring(_rhythm.length));
      return rhythm == null ? UnknownScope(value) : RhythmScope(rhythm);
    }
    if (value.startsWith(_catalog)) {
      final codes = [
        for (final code in value.substring(_catalog.length).split(','))
          if (code.trim().isNotEmpty) code.trim(),
      ];
      return codes.isEmpty ? UnknownScope(value) : CatalogLevelScope(codes);
    }
    return UnknownScope(value);
  }

  String get wire;

  @override
  List<Object?> get props => [wire];
}

final class SchoolScope extends CalendarScope {
  static const wireValue = 'SCHOOL';

  const SchoolScope();

  @override
  String get wire => wireValue;
}

final class CycleScope extends CalendarScope {
  final String cycleCode;

  const CycleScope(this.cycleCode);

  @override
  String get wire => '${CalendarScope._cycle}$cycleCode';
}

final class LevelScope extends CalendarScope {
  final String cycleCode;
  final String levelCode;

  const LevelScope({required this.cycleCode, required this.levelCode});

  @override
  String get wire => '${CalendarScope._level}$cycleCode/$levelCode';
}

final class RhythmScope extends CalendarScope {
  final PeriodRhythm rhythm;

  const RhythmScope(this.rhythm);

  @override
  String get wire => '${CalendarScope._rhythm}${rhythm.wire}';
}

/// Un ou plusieurs niveaux du catalogue national, séparés par des virgules
/// (`CATALOG_LEVEL:HG6,HS6,HP6` pour l'Exetat).
final class CatalogLevelScope extends CalendarScope {
  final List<String> catalogLevelCodes;

  const CatalogLevelScope(this.catalogLevelCodes);

  @override
  String get wire => '${CalendarScope._catalog}${catalogLevelCodes.join(',')}';
}

final class UnknownScope extends CalendarScope {
  final String raw;

  const UnknownScope(this.raw);

  @override
  String get wire => raw;
}

/// Ce qu'une classe sait d'elle-même pour savoir si un élément la concerne.
class ClassroomScopeKey extends Equatable {
  final String cycleCode;
  final String levelCode;
  final PeriodRhythm? rhythm;
  final String? catalogLevelCode;

  const ClassroomScopeKey({
    required this.cycleCode,
    required this.levelCode,
    this.rhythm,
    this.catalogLevelCode,
  });

  bool isConcernedBy(CalendarScope scope) => switch (scope) {
    SchoolScope() => true,
    CycleScope(:final cycleCode) => cycleCode == this.cycleCode,
    LevelScope(:final cycleCode, :final levelCode) =>
      cycleCode == this.cycleCode && levelCode == this.levelCode,
    RhythmScope(:final rhythm) => rhythm == this.rhythm,
    CatalogLevelScope(:final catalogLevelCodes) =>
      catalogLevelCode != null && catalogLevelCodes.contains(catalogLevelCode),
    UnknownScope() => false,
  };

  @override
  List<Object?> get props => [cycleCode, levelCode, rhythm, catalogLevelCode];
}
