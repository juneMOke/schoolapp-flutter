import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';

/// La table locale du journal et la forme de ses lignes.
abstract final class JournalTables {
  static const String entry = 'journal_seance';
}

/// Lignes `journal_seance` ↔ entités.
abstract final class JournalRowMapper {
  /// Les colonnes de la saisie : chapitre et sept champs.
  static Map<String, Object?> fieldColumns({
    required String? chapitreId,
    required JournalFields fields,
  }) => {
    'chapitre_id': chapitreId,
    'cb': fields.cb,
    'objectif': fields.objectif,
    'contenu': fields.contenu,
    'strategie': fields.strategie,
    'ressources': fields.ressources,
    'evaluation': fields.evaluation,
    'observation': fields.observation,
  };

  static JournalEntry toEntity(Map<String, Object?> row) => JournalEntry(
    id: row['id'] as String,
    coursId: row['cours_id'] as String,
    date: DateOnlyJsonHelper.fromJson(row['date_seance'] as String),
    timeSlotId: row['time_slot_id'] as String,
    chapitreId: row['chapitre_id'] as String?,
    fields: JournalFields(
      cb: _text(row['cb']),
      objectif: _text(row['objectif']),
      contenu: _text(row['contenu']),
      strategie: _text(row['strategie']),
      ressources: _text(row['ressources']),
      evaluation: _text(row['evaluation']),
      observation: _text(row['observation']),
    ),
    clientUpdatedAt: switch (row['client_updated_at']) {
      final String iso => DateTime.tryParse(iso),
      _ => null,
    },
    syncState: RecordSyncState.fromDb(row['sync_status'] as String?),
    rejectionCode: row['sync_error_code'] as String?,
  );

  static String _text(Object? value) => value is String ? value : '';
}
