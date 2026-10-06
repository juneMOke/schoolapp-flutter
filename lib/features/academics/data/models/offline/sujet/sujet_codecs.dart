import 'dart:convert';

import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

/// Codecs JSON du sujet, partagés par la colonne locale et le fil : la forme
/// stockée EST la forme envoyée, une seule traduction à maintenir.
///
/// Décodage tolérant partout — une colonne ou un delta mal formé rend une
/// liste vide ou un `null`, jamais une exception qui figerait un écran ou un
/// curseur de pull.
abstract final class SujetCodecs {
  /// `[{id, ordre, enonce, points, reponseAttendue}]` ; `ordre` = place + 1.
  static List<Map<String, Object?>> questionsToJson(
    List<SujetQuestion> questions,
  ) => [
    for (final (i, q) in questions.indexed)
      {
        'id': q.id,
        'ordre': i + 1,
        'enonce': q.enonce,
        'points': q.points,
        'reponseAttendue': q.reponseAttendue,
      },
  ];

  /// Questions triées par `ordre` ; une entrée sans `id` est écartée.
  static List<SujetQuestion> questionsFromJson(Object? raw) {
    if (raw is! List) return const [];
    final entries = <(int, SujetQuestion)>[];
    for (final (i, item) in raw.indexed) {
      if (item is! Map) continue;
      final id = item.text('id');
      if (id == null) continue;
      final points = item['points'];
      entries.add((
        item.integer('ordre') ?? i + 1,
        SujetQuestion(
          id: id,
          enonce: item['enonce'] is String ? item['enonce'] as String : '',
          points: points is num ? points.toDouble() : null,
          reponseAttendue: item.text('reponseAttendue'),
        ),
      ));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final e in entries) e.$2];
  }

  static List<String> programmeFromJson(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final line in raw)
        if (line is String && line.trim().isNotEmpty) line.trim(),
    ];
  }

  /// `{sujet, corrige, notes}`, chacun `null` ou
  /// `{publishedAt, updatedAt, revision}` (instants ISO-8601).
  static Map<String, Object?> publicationsToJson(EvaluationPublications p) => {
    for (final kind in PublicationKind.values)
      kind.pathSegment: _etatToJson(p.of(kind)),
  };

  static EvaluationPublications publicationsFromJson(Object? raw) {
    if (raw is! Map) return EvaluationPublications.none;
    var result = EvaluationPublications.none;
    for (final kind in PublicationKind.values) {
      result = result.withKind(kind, etatFromJson(raw[kind.pathSegment]));
    }
    return result;
  }

  /// Un état de publication ; `null` si absent ou sans `publishedAt` lisible.
  static PublicationEtat? etatFromJson(Object? raw) {
    if (raw is! Map) return null;
    final publishedAt = DateTime.tryParse(raw.text('publishedAt') ?? '');
    if (publishedAt == null) return null;
    return PublicationEtat(
      publishedAt: publishedAt.toUtc(),
      updatedAt: DateTime.tryParse(raw.text('updatedAt') ?? '')?.toUtc(),
      revision: raw.integer('revision') ?? 1,
    );
  }

  static Map<String, Object?>? _etatToJson(PublicationEtat? etat) =>
      etat == null
      ? null
      : {
          'publishedAt': etat.publishedAt.toUtc().toIso8601String(),
          'updatedAt': etat.updatedAt?.toUtc().toIso8601String(),
          'revision': etat.revision,
        };

  /// Décode une colonne JSON ; texte illisible → `null`.
  static Object? decodeColumn(Object? column) {
    if (column is! String || column.isEmpty) return null;
    try {
      return jsonDecode(column);
    } on FormatException {
      return null;
    }
  }
}
