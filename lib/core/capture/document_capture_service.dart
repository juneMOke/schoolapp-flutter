import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_failure.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/document_type_sniffer.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';

/// Obtient une pièce (caméra ou fichier) et la vérifie avant qu'elle ne soit
/// gardée sur la tablette : type reconnu à ses octets, poids sous le plafond
/// du serveur, empreinte calculée.
///
/// Ne garde rien lui-même : le module appelant scelle la pièce dans son
/// magasin chiffré et la met dans sa file d'envoi.
class DocumentCaptureService {
  final DocumentCaptureGateway _gateway;
  final DateTime Function() _now;

  DocumentCaptureService(this._gateway, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  Future<Either<DocumentCaptureFailure, CapturedDocument>> capture(
    DocumentCaptureMode mode,
  ) async {
    final RawCapture? raw;
    try {
      raw = await _gateway.acquire(mode);
    } on CameraUnavailableException {
      return const Left(CameraUnavailableFailure());
    } catch (_) {
      return const Left(DocumentReadFailure());
    }
    if (raw == null) return const Left(DocumentCaptureCancelled());

    final mimeType = DocumentTypeSniffer.sniff(raw.bytes);
    if (mimeType == null ||
        !DocumentCapturePolicy.acceptedTypes.contains(mimeType)) {
      return const Left(UnsupportedDocumentFailure());
    }
    if (raw.bytes.length > DocumentCapturePolicy.maxBytes) {
      return Left(DocumentTooLargeFailure(raw.bytes.length));
    }

    return Right(
      CapturedDocument(
        bytes: raw.bytes,
        mimeType: mimeType,
        source: mode.source,
        fileName: mode == DocumentCaptureMode.scan ? null : raw.fileName,
        sha256Hex: await sha256Hex(raw.bytes),
        capturedAt: _now(),
      ),
    );
  }
}
