import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';

/// [DocumentCaptureGateway] sur les greffons `image_picker` et `file_picker`.
///
/// Les images passent par `image_picker`, qui les réduit **nativement** au
/// grand côté et à la qualité de [DocumentCapturePolicy] : une photo de
/// tablette de 12 Mpx sortirait sinon au-delà du plafond du serveur. Les PDF
/// passent par `file_picker`, sans retouche — un PDF ne se réduit pas, il est
/// accepté ou refusé tel quel.
///
/// La caméra est celle du système : le cadre guide au format A4 de la
/// maquette demanderait le greffon `camera` et un écran de prise de vue à
/// nous, hors de ce socle.
class PlatformDocumentCaptureGateway implements DocumentCaptureGateway {
  /// Codes d'erreur par lesquels `image_picker` signale une caméra refusée ou
  /// absente (Android et iOS).
  static const Set<String> _cameraErrorCodes = {
    'camera_access_denied',
    'no_available_camera',
  };

  final ImagePicker _imagePicker;

  PlatformDocumentCaptureGateway({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<RawCapture?> acquire(DocumentCaptureMode mode) {
    return switch (mode) {
      DocumentCaptureMode.scan => _pickImage(ImageSource.camera),
      DocumentCaptureMode.importImage => _pickImage(ImageSource.gallery),
      DocumentCaptureMode.importPdf => _pickPdf(),
    };
  }

  Future<RawCapture?> _pickImage(ImageSource source) async {
    final XFile? file;
    try {
      file = await _imagePicker.pickImage(
        source: source,
        maxWidth: DocumentCapturePolicy.maxImageDimension,
        maxHeight: DocumentCapturePolicy.maxImageDimension,
        imageQuality: DocumentCapturePolicy.jpegQuality,
        // Ni géolocalisation ni date de prise de vue : une pièce d'identité n'a
        // pas à emporter l'endroit où elle a été photographiée.
        requestFullMetadata: false,
      );
    } on PlatformException catch (error) {
      if (source == ImageSource.camera &&
          _cameraErrorCodes.contains(error.code)) {
        throw const CameraUnavailableException();
      }
      rethrow;
    }
    if (file == null) return null;
    return RawCapture(bytes: await file.readAsBytes(), fileName: file.name);
  }

  Future<RawCapture?> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return RawCapture(bytes: bytes, fileName: file.name);
  }
}
