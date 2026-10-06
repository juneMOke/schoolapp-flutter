import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/push/programme_push_op.dart';

/// L'ajout ou la suppression d'une note de séance.
class ChapitreNotePayload {
  final ProgrammePushOp op;
  final String id;
  final String chapitreId;
  final String texte;
  final String ecriteLe;

  const ChapitreNotePayload({
    required this.op,
    required this.id,
    required this.chapitreId,
    this.texte = '',
    this.ecriteLe = '',
  });

  Map<String, Object?> toJson() => {
    'op': op.wireValue,
    'id': id,
    'chapitreId': chapitreId,
    'texte': texte,
    'ecriteLe': ecriteLe,
  };

  /// Le corps du `POST` d'ajout.
  Map<String, Object?> toBody() => {
    'id': id,
    'chapitreId': chapitreId,
    'texte': texte,
    'ecriteLe': ecriteLe,
  };

  static ChapitreNotePayload? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final op = ProgrammePushOp.fromWire(raw['op']);
    final id = pushString(raw['id']);
    final chapitreId = pushString(raw['chapitreId']);
    if (op == null || id == null || chapitreId == null) return null;
    return ChapitreNotePayload(
      op: op,
      id: id,
      chapitreId: chapitreId,
      texte: pushString(raw['texte']) ?? '',
      ecriteLe: pushString(raw['ecriteLe']) ?? '',
    );
  }
}

/// L'ajout ou le retrait d'une ressource. Les octets d'un document ne
/// voyagent pas dans l'outbox : le handler les relit dans le magasin chiffré.
class ChapitreRessourcePayload {
  final ProgrammePushOp op;
  final ChapitreRessourceDto ressource;
  final String chapitreId;

  const ChapitreRessourcePayload({
    required this.op,
    required this.ressource,
    required this.chapitreId,
  });

  /// La partie `metadata` de l'envoi multipart (ou le corps d'un lien).
  Map<String, Object?> toMetadata() => {
    'id': ressource.id,
    'type': ressource.type,
    'nom': ressource.nom,
    'url': ressource.url,
    'reference': ressource.reference,
    'taille': ressource.taille,
    'sha256': ressource.sha256,
    'mimeType': ressource.mimeType,
    'fileName': ressource.fileName,
  };

  Map<String, Object?> toJson() => {
    'op': op.wireValue,
    'chapitreId': chapitreId,
    'ressource': toMetadata(),
  };

  static ChapitreRessourcePayload? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final op = ProgrammePushOp.fromWire(raw['op']);
    final chapitreId = pushString(raw['chapitreId']);
    final ressource = ChapitreRessourceDto.tryParse(raw['ressource']);
    if (op == null || chapitreId == null || ressource == null) return null;
    return ChapitreRessourcePayload(
      op: op,
      ressource: ressource,
      chapitreId: chapitreId,
    );
  }
}
