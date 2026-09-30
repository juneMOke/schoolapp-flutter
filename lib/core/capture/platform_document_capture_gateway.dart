import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
///
/// ⚠️ Sur iOS, un appareil **sans caméra** ne lève rien : le greffon affiche
/// sa propre alerte puis rend `null`, que rien ne distingue d'un renoncement.
/// L'utilisateur est prévenu par le système et rouvre la feuille pour importer.
///
/// ⚠️ Sur Android, `requestFullMetadata: false` est **ignoré** : l'EXIF de
/// l'appareil photo, GPS compris, est recopiée dans l'image réduite. Le
/// service la retire ensuite (`JpegMetadataSanitizer`).
class PlatformDocumentCaptureGateway implements DocumentCaptureGateway {
  /// Codes d'erreur par lesquels `image_picker` signale une caméra refusée,
  /// bloquée par la gestion de flotte (MDM, fréquent en établissement) ou
  /// absente.
  static const Set<String> _cameraErrorCodes = {
    'camera_access_denied',
    'camera_access_restricted',
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
    // Plateforme sans prise de vue (bureau) : l'appel lèverait une erreur
    // générique, qui se lirait comme une lecture ratée.
    if (source == ImageSource.camera &&
        !_imagePicker.supportsImageSource(ImageSource.camera)) {
      throw const CameraUnavailableException();
    }
    final XFile? file;
    try {
      file = await _imagePicker.pickImage(
        source: source,
        maxWidth: DocumentCapturePolicy.maxImageDimension,
        maxHeight: DocumentCapturePolicy.maxImageDimension,
        imageQuality: DocumentCapturePolicy.jpegQuality,
        // Respecté sur iOS seulement ; voir la note sur Android plus haut.
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
    try {
      return RawCapture(bytes: await file.readAsBytes(), fileName: file.name);
    } finally {
      await _forget(file.path);
    }
  }

  Future<RawCapture?> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      // Les octets ne sont chargés d'office que sur le web, qui n'a pas de
      // chemin ; ailleurs, la taille est jugée avant toute lecture.
      withData: kIsWeb,
    );
    try {
      final file = result?.files.singleOrNull;
      if (file == null) return null;
      if (file.size > DocumentCapturePolicy.maxBytes) {
        throw DocumentTooLargeException(file.size);
      }
      final bytes = file.bytes ?? await file.xFile.readAsBytes();
      return RawCapture(bytes: bytes, fileName: file.name);
    } finally {
      // Le sélecteur copie le PDF dans le cache de l'application, même quand
      // il est refusé pour sa taille : une copie en clair qui survivrait.
      if (!kIsWeb) await _quietly(FilePicker.clearTemporaryFiles);
    }
  }

  /// Efface la copie que le sélecteur d'images laisse dans le cache de
  /// l'application — en clair, métadonnées GPS comprises : seuls les octets
  /// relus en mémoire sont nettoyés et scellés.
  static Future<void> _forget(String path) async {
    if (kIsWeb || path.isEmpty) return;
    await _quietly(() => File(path).delete());
  }

  /// Un ménage raté ne fait pas échouer une capture réussie.
  static Future<void> _quietly(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
