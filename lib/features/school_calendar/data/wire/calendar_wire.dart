import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_actor.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// Une ligne descendue, avec son horloge serveur.
class Pulled<T> {
  final T value;
  final int? serverUpdatedAtMs;

  const Pulled(this.value, this.serverUpdatedAtMs);
}

/// Un événement descendu ou rendu par le lot : la ligne, et sa marque de
/// suppression.
class PulledEvent {
  final SchoolEventRecord record;
  final int? serverUpdatedAtMs;

  const PulledEvent(this.record, this.serverUpdatedAtMs);
}

/// La lecture et l'écriture du fil du calendrier (contrat figé avec le back
/// le 2026-11-19). Une ligne illisible lève : la page la saute et la compte
/// (`ParsedKeysetPage`), sans emporter les autres.
class CalendarWire {
  const CalendarWire._();

  static String _string(Map j, String key) {
    final value = j[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('champ $key absent');
    }
    return value;
  }

  static DateTime _date(Map j, String key) =>
      CalendarDays.tryParse(j[key] as String?) ??
      (throw FormatException('date $key illisible'));

  static DateTime? _instant(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString())?.toUtc();

  static int? _int(Object? raw) => raw is num ? raw.toInt() : null;

  static Pulled<NationalFramework> frameworkFromJson(Object? raw) {
    final j = raw as Map<String, dynamic>;
    final yearLabel = _string(j, 'yearLabel');
    return Pulled(
      NationalFramework(
        id: _string(j, 'id'),
        yearLabel: yearLabel,
        version: _int(j['version']) ?? 0,
        startDate: _date(j, 'startDate'),
        endDate: _date(j, 'endDate'),
        items: [
          for (final item in (j['items'] as List?) ?? const [])
            _nationalItem(item as Map<String, dynamic>),
        ],
        document: _document(j['document']),
      ),
      EpochIsoHelper.tryToEpochMs(j['serverUpdatedAt']),
    );
  }

  /// `{fileName, sizeBytes, uploadedAt}` ou `null` ; sans nom, pas de
  /// document (rien à ouvrir).
  static FrameworkDocument? _document(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['fileName'];
    if (name is! String || name.isEmpty) return null;
    return FrameworkDocument(
      fileName: name,
      sizeBytes: _int(raw['sizeBytes']),
      uploadedAt: _instant(raw['uploadedAt']),
    );
  }

  static CalendarElement _nationalItem(Map<String, dynamic> j) =>
      CalendarElement(
        id: _string(j, 'id'),
        source: CalendarSource.national,
        nature: CalendarNature.fromWire(j['nature'] as String?),
        title: (j['title'] as String?) ?? '',
        startDate: _date(j, 'startDate'),
        endDate: _date(j, 'endDate'),
        scope: CalendarScope.parse(j['scope'] as String?),
        rhythm: PeriodRhythm.fromWire(j['rhythm'] as String?),
        periodOrder: _int(j['periodOrder']),
        subPeriodOrder: _int(j['subPeriodOrder']),
        replaceable: j['replaceable'] == true,
      );

  static Pulled<SchoolCalendar> calendarFromJson(Object? raw) {
    final j = raw as Map<String, dynamic>;
    return Pulled(
      SchoolCalendar(
        id: _string(j, 'id'),
        yearLabel: _string(j, 'yearLabel'),
        status: CalendarStatus.fromWire(j['status'] as String?),
        startDate: _date(j, 'startDate'),
        endDate: _date(j, 'endDate'),
        framework: FrameworkState.fromWire(j['framework'] as String?),
        frameworkVersion: _int(j['frameworkVersion']),
        publishedAt: _instant(j['publishedAt']),
        publishedBy: CalendarActor.fromJson(j['publishedBy']),
        updatedAt: _instant(j['updatedAt']),
        revision: _int(j['revision']) ?? 0,
      ),
      EpochIsoHelper.tryToEpochMs(j['serverUpdatedAt']),
    );
  }

  static PulledEvent eventFromJson(Object? raw) {
    final j = raw as Map<String, dynamic>;
    final element = CalendarElement(
      id: _string(j, 'id'),
      source: CalendarSource.school,
      nature: CalendarNature.fromWire(j['nature'] as String?),
      title: (j['title'] as String?) ?? '',
      startDate: _date(j, 'startDate'),
      endDate: _date(j, 'endDate'),
      scope: CalendarScope.parse(j['scope'] as String?),
      note: j['note'] as String?,
      toVerify: j['toVerify'] == true,
      createdBy: CalendarActor.fromJson(j['createdBy']),
      replaces: switch (j['replacesItemId']) {
        final String id when id.isNotEmpty => id,
        _ => null,
      },
    );
    return PulledEvent(
      SchoolEventRecord(
        element: element,
        calendarId: _string(j, 'calendarId'),
        clientUpdatedAtMs:
            EpochIsoHelper.tryToEpochMs(j['clientUpdatedAt']) ?? 0,
        deleted: j['deleted'] == true,
      ),
      EpochIsoHelper.tryToEpochMs(j['serverUpdatedAt']),
    );
  }

  /// Une ligne du lot montant : l'élément entier, ou `deleted:true` (A7).
  /// `toVerify` ne part que pour retirer la marque : un `true` serait ignoré.
  static Map<String, dynamic> eventToJson(SchoolEventRecord record) {
    final e = record.element;
    return {
      'id': e.id,
      'calendarId': record.calendarId,
      'nature': e.nature.wire,
      'title': e.title,
      'startDate': CalendarDays.format(e.startDate),
      'endDate': CalendarDays.format(e.endDate),
      'scope': e.scope.wire,
      'note': e.note,
      'toVerify': e.toVerify,
      'replacesItemId': e.replaces,
      'deleted': record.deleted,
      'clientUpdatedAt': EpochIsoHelper.toIso(record.clientUpdatedAtMs),
    };
  }
}
