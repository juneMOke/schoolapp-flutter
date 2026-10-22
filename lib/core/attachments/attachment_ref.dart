import 'package:equatable/equatable.dart';

/// Une pièce rangée côté serveur, décrite sans ses octets : ce que le pull
/// fait descendre d'une justification d'absence ou d'une copie déposée.
///
/// Les octets ne descendent jamais avec la ligne. Ils se téléchargent à la
/// demande, et [sha256] est à la fois leur empreinte et l'`ETag` qui permet au
/// serveur de répondre 304 sans les renvoyer.
class AttachmentRef extends Equatable {
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String sha256;

  const AttachmentRef({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
  });

  bool get isPdf => mimeType == 'application/pdf';

  bool get isImage => mimeType.startsWith('image/');

  /// Une pièce illisible côté client (ni PDF, ni image) ne s'ouvre pas : la
  /// visionneuse ne sait rien en faire.
  bool get isViewable => isPdf || isImage;

  /// Tolérant : `null` sur une description incomplète plutôt qu'une levée, pour
  /// qu'une pièce mal décrite n'empêche pas la ligne qui la porte de descendre.
  static AttachmentRef? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final name = json['name'] ?? json['nom'];
    final mime = json['mimeType'];
    final size = json['sizeBytes'];
    final sha = json['sha256'];
    if (name is! String || mime is! String || sha is! String || sha.isEmpty) {
      return null;
    }
    return AttachmentRef(
      name: name,
      mimeType: mime,
      sizeBytes: size is num ? size.toInt() : 0,
      sha256: sha,
    );
  }

  @override
  List<Object?> get props => [name, mimeType, sizeBytes, sha256];
}
