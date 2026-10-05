import 'package:school_app_flutter/features/course_programme/data/local/chapitre_fiche_codec.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';

// Les payloads d'outbox du programme et les accusés du serveur. Parsés à la
// main, comme les autres modèles offline : le round-trip `toJson` → `tryParse`
// EST le chemin du push (l'outbox range le texte, le handler le relit).

/// Ce que porte une entrée : un enregistrement ou une suppression.
enum ProgrammePushOp {
  save('save'),
  delete('delete');

  const ProgrammePushOp(this.wireValue);

  final String wireValue;

  static ProgrammePushOp? fromWire(Object? value) =>
      values.where((op) => op.wireValue == value).firstOrNull;
}

String? _string(Object? value) => value is String ? value : null;

/// La fiche d'un chapitre telle qu'elle part (`POST /sync/academics/chapitres`)
/// — sans `ordre`, que seul le geste d'ordre change.
class ChapitreFichePayload {
  final ProgrammePushOp op;
  final String chapitreId;
  final String coursId;
  final Map<String, Object?> fiche;

  const ChapitreFichePayload._(
    this.op,
    this.chapitreId,
    this.coursId,
    this.fiche,
  );

  factory ChapitreFichePayload.save(Chapitre chapitre) =>
      ChapitreFichePayload._(
        ProgrammePushOp.save,
        chapitre.id,
        chapitre.coursId,
        {
          'id': chapitre.id,
          'coursId': chapitre.coursId,
          'titre': chapitre.titre,
          'resume': chapitre.resume,
          'statut': chapitre.statut.wireValue,
          'seances': chapitre.seances,
          'sousPeriodeId': chapitre.sousPeriodeId,
          'objectifs': ChapitreFicheCodec.objectifsToJson(chapitre.objectifs),
          'strategies': chapitre.strategies,
          'blocs': ChapitreFicheCodec.blocsToJson(chapitre.blocs),
          'clientUpdatedAt': chapitre.clientUpdatedAt
              ?.toUtc()
              .toIso8601String(),
        },
      );

  factory ChapitreFichePayload.delete({
    required String chapitreId,
    required String coursId,
  }) => ChapitreFichePayload._(
    ProgrammePushOp.delete,
    chapitreId,
    coursId,
    const {},
  );

  /// L'horloge de la fiche envoyée ; c'est elle que l'accusé compare à la
  /// ligne locale.
  String? get clientUpdatedAt => _string(fiche['clientUpdatedAt']);

  Map<String, Object?> toJson() => {
    'op': op.wireValue,
    'chapitreId': chapitreId,
    'coursId': coursId,
    'fiche': fiche,
  };

  static ChapitreFichePayload? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final op = ProgrammePushOp.fromWire(raw['op']);
    final chapitreId = _string(raw['chapitreId']);
    final coursId = _string(raw['coursId']);
    final fiche = raw['fiche'];
    if (op == null || chapitreId == null || coursId == null || fiche is! Map) {
      return null;
    }
    return ChapitreFichePayload._(
      op,
      chapitreId,
      coursId,
      Map<String, Object?>.from(fiche),
    );
  }
}

/// L'accusé d'un envoi de fiche : la fiche que le serveur a retenue, et s'il a
/// appliqué la nôtre ou l'a ignorée (plus ancienne que la sienne).
class ChapitreFicheAck {
  final ChapitreDto chapitre;
  final bool ignored;

  const ChapitreFicheAck({required this.chapitre, required this.ignored});

  /// Lève [FormatException] sur un accusé sans chapitre lisible : le handler
  /// le traite en échec local, donc en tentative — l'envoi est rejouable.
  factory ChapitreFicheAck.fromJson(Map<String, dynamic> json) {
    final chapitre =
        ChapitreDto.tryParse(json['chapitre']) ?? ChapitreDto.tryParse(json);
    if (chapitre == null) {
      throw const FormatException('Accusé de chapitre illisible');
    }
    return ChapitreFicheAck(
      chapitre: chapitre,
      ignored: json['verdict'] == 'IGNORED',
    );
  }
}

/// L'ordre voulu des chapitres d'un cours — la liste **complète** des ids.
class ChapitreOrdrePayload {
  final String coursId;
  final List<String> chapitreIds;
  final String clientUpdatedAt;

  const ChapitreOrdrePayload({
    required this.coursId,
    required this.chapitreIds,
    required this.clientUpdatedAt,
  });

  Map<String, Object?> toJson() => {
    'coursId': coursId,
    'chapitreIds': chapitreIds,
    'clientUpdatedAt': clientUpdatedAt,
  };

  /// Le corps du `PUT` (le cours est dans le chemin).
  Map<String, Object?> toBody() => {
    'chapitreIds': chapitreIds,
    'clientUpdatedAt': clientUpdatedAt,
  };

  static ChapitreOrdrePayload? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final coursId = _string(raw['coursId']);
    final ids = raw['chapitreIds'];
    final at = _string(raw['clientUpdatedAt']);
    if (coursId == null || ids is! List || at == null) return null;
    return ChapitreOrdrePayload(
      coursId: coursId,
      chapitreIds: ids.whereType<String>().toList(growable: false),
      clientUpdatedAt: at,
    );
  }
}

/// L'ordre retenu par le serveur, chapitres créés ailleurs compris.
class ChapitreOrdreAck {
  final List<String> chapitreIds;

  const ChapitreOrdreAck(this.chapitreIds);

  factory ChapitreOrdreAck.fromJson(Map<String, dynamic> json) {
    final ids = json['chapitreIds'];
    if (ids is! List) throw const FormatException('Ordre retenu illisible');
    return ChapitreOrdreAck(ids.whereType<String>().toList(growable: false));
  }
}

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
    final id = _string(raw['id']);
    final chapitreId = _string(raw['chapitreId']);
    if (op == null || id == null || chapitreId == null) return null;
    return ChapitreNotePayload(
      op: op,
      id: id,
      chapitreId: chapitreId,
      texte: _string(raw['texte']) ?? '',
      ecriteLe: _string(raw['ecriteLe']) ?? '',
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
    final chapitreId = _string(raw['chapitreId']);
    final ressource = ChapitreRessourceDto.tryParse(raw['ressource']);
    if (op == null || chapitreId == null || ressource == null) return null;
    return ChapitreRessourcePayload(
      op: op,
      ressource: ressource,
      chapitreId: chapitreId,
    );
  }
}
