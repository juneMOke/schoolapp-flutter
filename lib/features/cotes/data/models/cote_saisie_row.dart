import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';

/// `cote_saisie` ↔ [CoteCell].
CoteCell coteCellFromRow(Map<String, Object?> row) => CoteCell(
  key: coteKeyFromRow(row),
  serverCote: (row['server_cote'] as num?)?.toDouble(),
  calculee: (row['calculee'] as num?)?.toDouble(),
  serverUpdatedAtMs: row['server_updated_at'] as int?,
  hasDraft: row['has_draft'] == 1,
  draftValue: (row['draft_valeur'] as num?)?.toDouble(),
  draftUpdatedAtMs: row['draft_updated_at'] as int?,
  syncState: SyncState.fromDbValue(row['sync_status'] as String?),
  rejectionReason: row['rejection_reason'] as String?,
  invalidRaw: row['invalid_raw'] as String?,
);

CoteCellKey coteKeyFromRow(Map<String, Object?> row) => CoteCellKey(
  studentId: row['student_id'] as String,
  coursId: row['cours_id'] as String,
  colonneId: row['colonne_id'] as String,
  examen: row['examen'] == 1,
);
