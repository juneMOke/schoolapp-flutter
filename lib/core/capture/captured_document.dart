import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Type d'une pièce, **reconnu à ses premiers octets** et jamais à son
/// extension : un fichier renommé `.pdf` reste ce qu'il est.
enum DocumentMimeType {
  jpeg('image/jpeg'),
  png('image/png'),
  pdf('application/pdf'),
  docx(
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),
  doc('application/msword');

  const DocumentMimeType(this.value);

  /// Type MIME, tel qu'il part dans la partie `metadata` d'un envoi.
  final String value;

  bool get isImage =>
      this == DocumentMimeType.jpeg || this == DocumentMimeType.png;
}

/// Origine d'une pièce : photographiée depuis l'application, ou choisie parmi
/// les fichiers de la tablette.
enum DocumentCaptureSource { scan, import }

/// Geste choisi par l'utilisateur pour obtenir une pièce.
enum DocumentCaptureMode {
  /// Photographier la pièce avec la caméra.
  scan,

  /// Choisir une photo déjà présente sur la tablette.
  importImage,

  /// Choisir un PDF déjà présent sur la tablette.
  importPdf;

  DocumentCaptureSource get source => this == DocumentCaptureMode.scan
      ? DocumentCaptureSource.scan
      : DocumentCaptureSource.import;
}

/// Une pièce obtenue, vérifiée, prête à être scellée sur la tablette.
class CapturedDocument extends Equatable {
  final Uint8List bytes;
  final DocumentMimeType mimeType;
  final DocumentCaptureSource source;

  /// Nom d'origine du fichier importé ; `null` pour une numérisation.
  final String? fileName;

  /// SHA-256 des octets, en hexadécimal minuscule : c'est ce qui rend le rejeu
  /// d'un envoi sans effet côté serveur.
  final String sha256Hex;

  /// Moment de la capture, sur l'horloge de la tablette.
  final DateTime capturedAt;

  const CapturedDocument({
    required this.bytes,
    required this.mimeType,
    required this.source,
    required this.sha256Hex,
    required this.capturedAt,
    this.fileName,
  });

  int get sizeBytes => bytes.length;

  @override
  List<Object?> get props => [
    sha256Hex,
    mimeType,
    source,
    fileName,
    capturedAt,
  ];
}
