import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_digest.dart';
import 'package:school_app_flutter/core/capture/document_capture_failure.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/document_type_sniffer.dart';

/// Obtient une pièce (caméra ou fichier) et la vérifie avant qu'elle ne soit
/// gardée sur la tablette : type reconnu à ses octets, métadonnées de
/// localisation retirées d'un JPEG, poids sous le plafond du serveur, empreinte
/// calculée — ces deux derniers calculs hors du fil d'interface.
///
/// Ne garde rien lui-même : le module appelant scelle la pièce dans son
/// magasin chiffré et la met dans sa file d'envoi.
class DocumentCaptureService {
  final DocumentCaptureGateway _gateway;
  final DocumentDigester _digest;
  final DateTime Function() _now;

  DocumentCaptureService(
    this._gateway, {
    DocumentDigester digest = digestDocumentInIsolate,
    DateTime Function()? now,
  }) : _digest = digest,
       _now = now ?? DateTime.now;

  Future<Either<DocumentCaptureFailure, CapturedDocument>> capture(
    DocumentCaptureMode mode,
  ) async {
    final RawCapture? raw;
    try {
      raw = await _gateway.acquire(mode);
    } on CameraUnavailableException {
      return const Left(CameraUnavailableFailure());
    } on DocumentTooLargeException catch (error) {
      return Left(DocumentTooLargeFailure(error.sizeBytes));
    } catch (_) {
      return const Left(DocumentReadFailure());
    }
    if (raw == null) return const Left(DocumentCaptureCancelled());

    final mimeType = DocumentTypeSniffer.sniff(raw.bytes);
    if (mimeType == null ||
        !DocumentCapturePolicy.acceptedTypes.contains(mimeType)) {
      return const Left(UnsupportedDocumentFailure());
    }
    // Jugé avant le calcul : inutile de nettoyer et d'empreinter ce qui sera
    // refusé. Le nettoyage ne fait que retirer des octets, il ne peut pas
    // faire passer la pièce au-dessus du plafond.
    if (raw.bytes.length > DocumentCapturePolicy.maxBytes) {
      return Left(DocumentTooLargeFailure(raw.bytes.length));
    }

    final DocumentDigest digest;
    try {
      digest = await _digest(raw.bytes, mimeType);
    } catch (_) {
      return const Left(DocumentReadFailure());
    }

    return Right(
      CapturedDocument(
        bytes: digest.bytes,
        mimeType: mimeType,
        source: mode.source,
        fileName: mode == DocumentCaptureMode.scan ? null : raw.fileName,
        sha256Hex: digest.sha256Hex,
        capturedAt: _now(),
      ),
    );
  }
}
