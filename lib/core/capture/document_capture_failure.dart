import 'package:school_app_flutter/core/error/failures.dart';

/// Pourquoi aucune pièce n'a été obtenue.
///
/// Les messages sont des repères de journal ; l'écran affiche ses propres
/// textes localisés, choisis sur le **type** de l'échec.
sealed class DocumentCaptureFailure extends Failure {
  const DocumentCaptureFailure(super.message);
}

/// L'utilisateur a refermé la caméra ou le sélecteur sans rien choisir. Ce
/// n'est pas une erreur à lui signaler.
class DocumentCaptureCancelled extends DocumentCaptureFailure {
  const DocumentCaptureCancelled() : super('capture annulée');
}

/// La caméra est refusée ou absente. L'écran propose alors l'import, pour ne
/// jamais laisser l'utilisateur sans issue.
class CameraUnavailableFailure extends DocumentCaptureFailure {
  const CameraUnavailableFailure() : super('caméra indisponible');
}

/// La pièce dépasse le plafond du serveur.
class DocumentTooLargeFailure extends DocumentCaptureFailure {
  final int sizeBytes;

  const DocumentTooLargeFailure(this.sizeBytes)
    : super('pièce trop volumineuse');

  @override
  List<Object?> get props => [message, sizeBytes];
}

/// Les octets ne sont ni un JPEG, ni un PNG, ni un PDF.
class UnsupportedDocumentFailure extends DocumentCaptureFailure {
  const UnsupportedDocumentFailure() : super('type de pièce non accepté');
}

/// La plateforme n'a pas pu rendre le fichier (lecture impossible, plugin en
/// échec).
class DocumentReadFailure extends DocumentCaptureFailure {
  const DocumentReadFailure() : super('lecture de la pièce impossible');
}
