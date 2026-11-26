import 'package:school_app_flutter/core/capture/captured_document.dart';

/// Ce qu'une pièce numérisée ou importée doit respecter avant d'être gardée
/// sur la tablette — **une politique par usage**, aux bornes du serveur qui la
/// recevra.
///
/// Les bornes sont vérifiées **avant** la mise en file d'envoi : une pièce qui
/// les dépasse serait refusée en 422 terminal (`DOCUMENT_TOO_LARGE`) des
/// heures plus tard, loin de celui qui pouvait en choisir une autre.
class DocumentCapturePolicy {
  /// Plafond par fichier, en mégaoctets au sens de Spring (× 1024²).
  final int maxMegabytes;

  /// Types acceptés par le serveur.
  final Set<DocumentMimeType> acceptedTypes;

  /// Extensions proposées par le sélecteur de fichiers (hors images).
  final List<String> fileExtensions;

  /// Grand côté d'une image réduite, pour **cet** usage.
  final double imageMaxDimension;

  /// Qualité JPEG d'une image réduite (0–100), pour **cet** usage.
  final int imageJpegQuality;

  const DocumentCapturePolicy({
    required this.maxMegabytes,
    required this.acceptedTypes,
    required this.fileExtensions,
    this.imageMaxDimension = maxImageDimension,
    this.imageJpegQuality = jpegQuality,
  });

  /// Les pièces du dossier du personnel : 5 Mo (`spring.servlet.multipart`,
  /// réglé pour toute l'application depuis le logo V126), image ou PDF.
  static const DocumentCapturePolicy staffDocument = DocumentCapturePolicy(
    maxMegabytes: 5,
    acceptedTypes: {
      DocumentMimeType.jpeg,
      DocumentMimeType.png,
      DocumentMimeType.pdf,
    },
    fileExtensions: ['pdf'],
  );

  /// Les ressources d'un chapitre : 10 Mo (décision 3 du programme de cours),
  /// image, PDF ou document Word.
  static const DocumentCapturePolicy courseResource = DocumentCapturePolicy(
    maxMegabytes: 10,
    acceptedTypes: {
      DocumentMimeType.jpeg,
      DocumentMimeType.png,
      DocumentMimeType.pdf,
      DocumentMimeType.docx,
      DocumentMimeType.doc,
    },
    fileExtensions: ['pdf', 'doc', 'docx'],
  );

  /// La photo du bon d'une dépense déclarée : 5 Mo comme toute pièce, image
  /// ou PDF, mais réduite plus fort (1 600 px, qualité 80, environ 300 Ko) —
  /// elle voyage dans la file d'envoi d'une tablette souvent hors ligne, et
  /// un bon se lit très bien à cette taille. Le WebP accepté par le serveur
  /// n'est jamais produit ici : toute image prise ou importée est réencodée.
  static const DocumentCapturePolicy expenseVoucher = DocumentCapturePolicy(
    maxMegabytes: 5,
    acceptedTypes: {
      DocumentMimeType.jpeg,
      DocumentMimeType.png,
      DocumentMimeType.pdf,
    },
    fileExtensions: ['pdf'],
    imageMaxDimension: 1600,
    imageJpegQuality: 80,
  );

  int get maxBytes => maxMegabytes * 1024 * 1024;

  /// Le sélecteur de fichiers propose aussi des documents Word.
  bool get acceptsWord =>
      acceptedTypes.contains(DocumentMimeType.docx) ||
      acceptedTypes.contains(DocumentMimeType.doc);

  /// Grand côté **par défaut** d'une image après réduction : assez pour lire
  /// une pièce A4, assez peu pour qu'une photo d'appareil tienne sous le
  /// plafond.
  static const double maxImageDimension = 2000;

  /// Qualité JPEG d'une image réduite (0–100).
  static const int jpegQuality = 82;
}
