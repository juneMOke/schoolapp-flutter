import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_fiche_codec.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';

String? _string(Object? value) => value is String ? value : null;

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// Une note de séance telle qu'elle descend.
class ChapitreNoteDto {
  final String id;
  final String texte;
  final String ecriteLe;
  final String? auteur;

  const ChapitreNoteDto({
    required this.id,
    required this.texte,
    required this.ecriteLe,
    this.auteur,
  });

  static ChapitreNoteDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = _string(raw['id']);
    final texte = _string(raw['texte']);
    final ecriteLe = _string(raw['ecriteLe']);
    if (id == null || texte == null || ecriteLe == null) return null;
    return ChapitreNoteDto(
      id: id,
      texte: texte,
      ecriteLe: ecriteLe,
      auteur: _string(raw['auteur']),
    );
  }

  ChapitreNote toEntity(String chapitreId) => ChapitreNote(
    id: id,
    chapitreId: chapitreId,
    texte: texte,
    ecriteLe: _instant(ecriteLe) ?? DateTime.utc(1970),
    auteur: auteur,
  );
}

/// La description d'une ressource telle qu'elle descend ; le fichier d'un
/// document se télécharge à part.
class ChapitreRessourceDto {
  final String id;
  final String type;
  final String nom;
  final String? url;
  final String? reference;
  final int? taille;
  final String? sha256;
  final String? mimeType;
  final String? fileName;

  const ChapitreRessourceDto({
    required this.id,
    required this.type,
    required this.nom,
    this.url,
    this.reference,
    this.taille,
    this.sha256,
    this.mimeType,
    this.fileName,
  });

  static ChapitreRessourceDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = _string(raw['id']);
    final type = _string(raw['type']);
    final nom = _string(raw['nom']);
    if (id == null || type == null || nom == null) return null;
    final taille = raw['taille'];
    return ChapitreRessourceDto(
      id: id,
      type: type,
      nom: nom,
      url: _string(raw['url']),
      reference: _string(raw['reference']),
      taille: taille is num ? taille.toInt() : null,
      sha256: _string(raw['sha256']),
      mimeType: _string(raw['mimeType']),
      fileName: _string(raw['fileName']),
    );
  }

  ChapitreRessource toEntity(String chapitreId) => ChapitreRessource(
    id: id,
    chapitreId: chapitreId,
    type: RessourceType.fromWire(type),
    nom: nom,
    url: url,
    reference: reference,
    taille: taille,
    sha256: sha256,
    mimeType: mimeType,
    fileName: fileName,
  );
}

/// Un chapitre **entier** tel que le serveur le tient : la fiche, ses notes,
/// la description de ses ressources. C'est la forme du flux de descente, de
/// la fiche retenue rendue par un envoi, et de la lecture en ligne.
class ChapitreDto {
  final String id;
  final String coursId;
  final int ordre;
  final String titre;
  final String? resume;
  final String statut;
  final int seances;
  final String? sousPeriodeId;
  final List<ChapitreObjectif> objectifs;
  final List<String> strategies;
  final List<ChapitreBloc> blocs;
  final List<ChapitreNoteDto> notes;
  final List<ChapitreRessourceDto> ressources;
  final String? clientUpdatedAt;
  final String? serverUpdatedAt;

  const ChapitreDto({
    required this.id,
    required this.coursId,
    required this.ordre,
    required this.titre,
    this.resume,
    required this.statut,
    required this.seances,
    this.sousPeriodeId,
    this.objectifs = const [],
    this.strategies = const [],
    this.blocs = const [],
    this.notes = const [],
    this.ressources = const [],
    this.clientUpdatedAt,
    this.serverUpdatedAt,
  });

  /// Lecture tolérante : `null` si l'identité manque ; une note ou une
  /// ressource illisible est écartée sans emporter le chapitre.
  static ChapitreDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = _string(raw['id']);
    final coursId = _string(raw['coursId']);
    final titre = _string(raw['titre']);
    if (id == null || coursId == null || titre == null) return null;
    final ordre = raw['ordre'];
    final seances = raw['seances'];
    return ChapitreDto(
      id: id,
      coursId: coursId,
      ordre: ordre is num ? ordre.toInt() : 0,
      titre: titre,
      resume: _string(raw['resume']),
      statut: _string(raw['statut']) ?? ChapitreStatut.planifie.wireValue,
      seances: seances is num ? seances.toInt() : Chapitre.defaultSeances,
      sousPeriodeId: _string(raw['sousPeriodeId']),
      objectifs: ChapitreFicheCodec.objectifsFromJson(raw['objectifs']),
      strategies: ChapitreFicheCodec.strategiesFromJson(raw['strategies']),
      blocs: ChapitreFicheCodec.blocsFromJson(raw['blocs']),
      notes: _list(raw['notes'], ChapitreNoteDto.tryParse),
      ressources: _list(raw['ressources'], ChapitreRessourceDto.tryParse),
      clientUpdatedAt: _string(raw['clientUpdatedAt']),
      serverUpdatedAt: _string(raw['serverUpdatedAt']),
    );
  }

  static List<T> _list<T>(Object? raw, T? Function(Object?) parse) => [
    if (raw is List)
      for (final item in raw) ?parse(item),
  ];

  /// Le chapitre tel que l'écran le lit. [readOnly] : lu en ligne, aucun
  /// geste ne doit en partir.
  Chapitre toEntity({bool readOnly = false}) => Chapitre(
    id: id,
    coursId: coursId,
    ordre: ordre,
    titre: titre,
    resume: resume,
    statut: ChapitreStatut.fromWire(statut),
    seances: seances,
    sousPeriodeId: sousPeriodeId,
    objectifs: objectifs,
    strategies: strategies,
    blocs: blocs,
    notes: [for (final note in notes) note.toEntity(id)],
    ressources: [for (final r in ressources) r.toEntity(id)],
    clientUpdatedAt: _instant(clientUpdatedAt),
    readOnly: readOnly,
  );
}

/// Une page du flux des chapitres d'un cours.
class ChapitrePageDto extends ParsedKeysetPage<ChapitreDto> {
  const ChapitrePageDto({required super.items, required super.page});

  factory ChapitrePageDto.fromJson(Map<String, dynamic> json) {
    final parsed = ParsedKeysetPage.fromJson(json, ChapitreDto.tryParse);
    return ChapitrePageDto(items: parsed.items, page: parsed.page);
  }
}
