import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// Le versement d'une pièce tel qu'il part : la partie `metadata` du
/// multipart. Les octets n'y sont pas — ils attendent chiffrés dans le magasin
/// du module, sous l'[id] de la pièce, et sont relus à l'envoi.
class StaffDocumentUploadDto {
  final String id;

  /// L'agent : dans le chemin de la route, pas dans la partie `metadata`.
  final String staffMemberId;
  final String code;
  final String source;
  final String capturedAt;
  final String? fileName;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final String authorId;

  const StaffDocumentUploadDto({
    required this.id,
    required this.staffMemberId,
    required this.code,
    required this.source,
    required this.capturedAt,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    required this.authorId,
    this.fileName,
  });

  /// La partie `metadata` envoyée.
  Map<String, dynamic> toMetadata() => {
    'id': id,
    'code': code,
    'source': source,
    'capturedAt': capturedAt,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    kOutboxAuthorIdKey: authorId,
  };

  /// Le payload figé de l'entrée d'outbox.
  Map<String, dynamic> toJson() => {
    ...toMetadata(),
    'staffMemberId': staffMemberId,
  };

  static StaffDocumentUploadDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final staffMemberId = raw.text('staffMemberId');
    final code = raw.text('code');
    final source = raw.text('source');
    final capturedAt = raw.text('capturedAt');
    final mimeType = raw.text('mimeType');
    final sizeBytes = raw.integer('sizeBytes');
    final sha256 = raw.text('sha256');
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (id == null ||
        staffMemberId == null ||
        code == null ||
        source == null ||
        capturedAt == null ||
        mimeType == null ||
        sizeBytes == null ||
        sha256 == null ||
        authorId == null) {
      return null;
    }
    return StaffDocumentUploadDto(
      id: id,
      staffMemberId: staffMemberId,
      code: code,
      source: source,
      capturedAt: capturedAt,
      fileName: raw.text('fileName'),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      sha256: sha256,
      authorId: authorId,
    );
  }
}

/// L'accusé d'un versement : la pièce telle que le serveur la range.
abstract final class StaffDocumentAck {
  /// Tolère `{document: {...}}` comme la pièce nue.
  static StaffDocumentDeltaDto parse(Object? json) {
    final body = json is Map && json['document'] is Map
        ? json['document']
        : json;
    final document = StaffDocumentDeltaDto.tryParse(body);
    if (document == null) {
      throw const FormatException('Accusé de pièce illisible');
    }
    return document;
  }
}
