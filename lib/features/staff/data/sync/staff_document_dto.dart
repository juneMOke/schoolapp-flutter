import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// Une pièce versée, sans ses octets (`StaffDocumentDelta`) — ne descend que
/// sous `hr.document.read`.
class StaffDocumentDeltaDto {
  final String id;
  final String staffMemberId;
  final String code;
  final String source;
  final String capturedAt;
  final String? fileName;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final int? version;
  final String? serverUpdatedAt;

  const StaffDocumentDeltaDto({
    required this.id,
    required this.staffMemberId,
    required this.code,
    required this.source,
    required this.capturedAt,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    this.fileName,
    this.version,
    this.serverUpdatedAt,
  });

  static StaffDocumentDeltaDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final staffMemberId = raw.text('staffMemberId');
    final code = raw.text('code');
    final source = raw.text('source');
    final capturedAt = raw.instant('capturedAt');
    final mimeType = raw.text('mimeType');
    final sizeBytes = raw.integer('sizeBytes');
    final sha256 = raw.text('sha256')?.toLowerCase();
    if (id == null ||
        staffMemberId == null ||
        code == null ||
        source == null ||
        capturedAt == null ||
        mimeType == null ||
        sizeBytes == null ||
        sha256 == null) {
      return null;
    }
    return StaffDocumentDeltaDto(
      id: id,
      staffMemberId: staffMemberId,
      code: code,
      source: source,
      capturedAt: capturedAt,
      fileName: raw.text('fileName'),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      sha256: sha256,
      version: raw.integer('version'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

/// Page du flux `hr.staff-documents`.
class StaffDocumentPageDto extends ParsedKeysetPage<StaffDocumentDeltaDto> {
  StaffDocumentPageDto._(ParsedKeysetPage<StaffDocumentDeltaDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StaffDocumentPageDto.fromJson(Map<String, dynamic> json) =>
      StaffDocumentPageDto._(
        ParsedKeysetPage.fromJson(json, StaffDocumentDeltaDto.tryParse),
      );
}
