import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';

/// Une entrée du journal telle qu'elle descend (flux, ou entrée retenue
/// rendue par un envoi).
class JournalEntryDto {
  final String id;
  final String coursId;

  /// Jour civil `AAAA-MM-JJ`.
  final String date;
  final String timeSlotId;
  final String? chapitreId;
  final JournalFields fields;
  final String? clientUpdatedAt;
  final String? serverUpdatedAt;

  const JournalEntryDto({
    required this.id,
    required this.coursId,
    required this.date,
    required this.timeSlotId,
    required this.fields,
    this.chapitreId,
    this.clientUpdatedAt,
    this.serverUpdatedAt,
  });

  /// `null` sans identité (id, cours, jour, créneau). Les sept champs sont
  /// lus tels quels : un texte saisi n'est jamais rogné.
  static JournalEntryDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final coursId = raw.text('coursId');
    final date = raw.day('date');
    final timeSlotId = raw.text('timeSlotId');
    if (id == null || coursId == null || date == null || timeSlotId == null) {
      return null;
    }
    String field(String key) => switch (raw[key]) {
      final String value => value,
      _ => '',
    };
    return JournalEntryDto(
      id: id,
      coursId: coursId,
      date: date,
      timeSlotId: timeSlotId,
      chapitreId: raw.text('chapitreId'),
      fields: JournalFields(
        cb: field('cb'),
        objectif: field('objectif'),
        contenu: field('contenu'),
        strategie: field('strategie'),
        ressources: field('ressources'),
        evaluation: field('evaluation'),
        observation: field('observation'),
      ),
      clientUpdatedAt: raw.instant('clientUpdatedAt'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }

  /// L'entrée telle que le serveur la détient — lue en ligne, donc
  /// synchronisée.
  JournalEntry toEntity() => JournalEntry(
    id: id,
    coursId: coursId,
    date: DateOnlyJsonHelper.fromJson(date),
    timeSlotId: timeSlotId,
    chapitreId: chapitreId,
    fields: fields,
    clientUpdatedAt: switch (clientUpdatedAt) {
      final String iso => DateTime.tryParse(iso),
      null => null,
    },
  );
}

/// Une page du flux `academics.journal` d'un cours.
class JournalEntryPageDto extends ParsedKeysetPage<JournalEntryDto> {
  const JournalEntryPageDto({required super.items, required super.page});

  factory JournalEntryPageDto.fromJson(Map<String, dynamic> json) {
    final parsed = ParsedKeysetPage.fromJson(json, JournalEntryDto.tryParse);
    return JournalEntryPageDto(items: parsed.items, page: parsed.page);
  }
}
