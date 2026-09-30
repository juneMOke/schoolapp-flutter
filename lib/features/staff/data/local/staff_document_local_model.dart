import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_push_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une ligne de `staff_documents` : les métadonnées d'une pièce.
class StaffDocumentLocalModel {
  final Map<String, Object?> row;

  const StaffDocumentLocalModel(this.row);

  static const String table = 'staff_documents';

  /// Colonnes d'une pièce descendue ou accusée : un fait figé, entièrement
  /// dit par le serveur.
  static Map<String, Object?> columns(
    StaffDocumentDeltaDto dto, {
    required String schoolId,
    required int nowMs,
  }) => {
    'id': dto.id,
    'school_id': schoolId,
    'staff_member_id': dto.staffMemberId,
    'code': dto.code,
    'source': dto.source,
    'captured_at': dto.capturedAt,
    'file_name': dto.fileName,
    'mime_type': dto.mimeType,
    'size_bytes': dto.sizeBytes,
    'sha256': dto.sha256,
    'version': dto.version,
    'server_updated_at': dto.serverUpdatedAt,
    'sync_status': StaffSyncState.synced.dbValue,
    'sync_error': null,
    'sync_error_code': null,
    'updated_at': nowMs,
  };

  /// Colonnes d'une pièce versée sur ce poste et pas encore accusée.
  static Map<String, Object?> pendingColumns(
    StaffDocumentUploadDto dto, {
    required String schoolId,
    required int nowMs,
  }) => {
    'id': dto.id,
    'school_id': schoolId,
    'staff_member_id': dto.staffMemberId,
    'code': dto.code,
    'source': dto.source,
    'captured_at': dto.capturedAt,
    'file_name': dto.fileName,
    'mime_type': dto.mimeType,
    'size_bytes': dto.sizeBytes,
    'sha256': dto.sha256,
    'sync_status': StaffSyncState.pending.dbValue,
    'updated_at': nowMs,
  };

  bool get isSynced => row['sync_status'] == StaffSyncState.synced.dbValue;

  /// Empreinte SHA-256 des octets, en hexadécimal minuscule.
  String get sha256 => row['sha256'] as String? ?? '';

  StaffDocument toEntity() {
    String? text(String key) => row[key] as String?;
    final rawCode = text('code') ?? '';
    return StaffDocument(
      id: text('id') ?? '',
      staffMemberId: text('staff_member_id') ?? '',
      code: StaffDocumentCode.fromWire(rawCode),
      rawCode: rawCode,
      source: StaffDocumentSource.fromWire(text('source')),
      capturedAt: text('captured_at') ?? '',
      fileName: text('file_name'),
      mimeType: text('mime_type') ?? '',
      sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
      syncState: StaffSyncState.fromDb(text('sync_status')),
      syncError: text('sync_error'),
    );
  }
}
