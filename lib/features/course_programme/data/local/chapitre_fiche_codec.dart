import 'dart:convert';

import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';

/// Les listes d'une fiche de chapitre, sous **une seule forme JSON** : celle du
/// fil, rangée telle quelle dans la ligne locale. Une seule lecture tolérante
/// pour les deux usages : un élément illisible est écarté, jamais fatal.
class ChapitreFicheCodec {
  ChapitreFicheCodec._();

  static List<Map<String, Object?>> objectifsToJson(
    List<ChapitreObjectif> objectifs,
  ) => [for (final o in objectifs) o.toJson()];

  static List<ChapitreObjectif> objectifsFromJson(Object? json) => [
    for (final item in _maps(json))
      if (item['id'] is String && item['texte'] is String)
        ChapitreObjectif(
          id: item['id'] as String,
          texte: item['texte'] as String,
          atteint: item['atteint'] == true,
        ),
  ];

  static List<String> strategiesFromJson(Object? json) => json is List
      ? json.whereType<String>().toList(growable: false)
      : const [];

  static List<Map<String, Object?>> blocsToJson(List<ChapitreBloc> blocs) => [
    for (final b in blocs) b.toJson(),
  ];

  static List<ChapitreBloc> blocsFromJson(Object? json) => [
    for (final item in _maps(json))
      if (item['id'] is String)
        ChapitreBloc(
          id: item['id'] as String,
          type: ChapitreBlocType.fromWire(item['type'] as String?),
          texte: (item['texte'] as String?) ?? '',
          items: strategiesFromJson(item['items']),
        ),
  ];

  /// Décode une colonne `*_json` ; une colonne illisible rend `null`.
  static Object? decodeColumn(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static Iterable<Map<String, Object?>> _maps(Object? json) =>
      json is List ? json.whereType<Map<String, Object?>>() : const [];
}
