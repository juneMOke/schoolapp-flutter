import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une pièce versée au dossier d'un agent — ses métadonnées. Les octets vivent
/// chiffrés hors de la base.
class StaffDocument extends Equatable {
  final String id;
  final String staffMemberId;

  /// `null` pour un code que ce poste ne connaît pas encore ([rawCode] le
  /// garde).
  final StaffDocumentCode? code;
  final String rawCode;
  final StaffDocumentSource? source;

  /// Instant de la numérisation ou de l'import (ISO-8601 UTC).
  final String capturedAt;
  final String? fileName;
  final String mimeType;
  final int sizeBytes;
  final StaffSyncState syncState;

  /// Pourquoi le serveur a refusé le versement.
  final String? syncError;

  const StaffDocument({
    required this.id,
    required this.staffMemberId,
    required this.code,
    required this.rawCode,
    required this.source,
    required this.capturedAt,
    required this.mimeType,
    required this.sizeBytes,
    required this.syncState,
    this.fileName,
    this.syncError,
  });

  bool get isImage => mimeType.startsWith('image/');

  @override
  List<Object?> get props => [
    id,
    staffMemberId,
    rawCode,
    source,
    capturedAt,
    fileName,
    mimeType,
    sizeBytes,
    syncState,
    syncError,
  ];
}
