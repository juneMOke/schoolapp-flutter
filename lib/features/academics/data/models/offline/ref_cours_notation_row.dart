import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

/// Parse une liste JSON **élément par élément** : une entrée malformée est
/// écartée sans faire échouer les autres (une seule période/sous-période
/// illisible ne doit pas annuler tout l'arbre — la garde de clôture en dépend).
List<T> _lenient<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // entrée écartée
    }
  }
  return List<T>.unmodifiable(out);
}

/// Squelette d'une sous-période mise en cache : id + ordre + statut d'ouverture
/// (valeur wire OUVERTE/CLOTUREE/UNKNOWN). Pas de libellé (dérivé client-side).
class NotationSousPeriodeSkeleton extends Equatable {
  final String sousPeriodeId;
  final int ordre;
  final String statut;

  const NotationSousPeriodeSkeleton({
    required this.sousPeriodeId,
    required this.ordre,
    required this.statut,
  });

  factory NotationSousPeriodeSkeleton.fromJson(Map<String, dynamic> j) =>
      NotationSousPeriodeSkeleton(
        sousPeriodeId: j['sousPeriodeId'] as String,
        ordre: (j['ordre'] as num?)?.toInt() ?? 0,
        statut: (j['statut'] as String?) ?? 'UNKNOWN',
      );

  Map<String, dynamic> toJson() => {
    'sousPeriodeId': sousPeriodeId,
    'ordre': ordre,
    'statut': statut,
  };

  @override
  List<Object?> get props => [sousPeriodeId, ordre, statut];
}

/// Squelette d'une grande période : id + ordre + statut + ses sous-périodes.
class NotationPeriodeSkeleton extends Equatable {
  final String periodeScolaireId;
  final int ordre;
  final String statut;
  final List<NotationSousPeriodeSkeleton> sousPeriodes;

  const NotationPeriodeSkeleton({
    required this.periodeScolaireId,
    required this.ordre,
    required this.statut,
    this.sousPeriodes = const [],
  });

  factory NotationPeriodeSkeleton.fromJson(Map<String, dynamic> j) =>
      NotationPeriodeSkeleton(
        periodeScolaireId: j['periodeScolaireId'] as String,
        ordre: (j['ordre'] as num?)?.toInt() ?? 0,
        statut: (j['statut'] as String?) ?? 'UNKNOWN',
        sousPeriodes: _lenient(
          j['sousPeriodes'],
          NotationSousPeriodeSkeleton.fromJson,
        ),
      );

  Map<String, dynamic> toJson() => {
    'periodeScolaireId': periodeScolaireId,
    'ordre': ordre,
    'statut': statut,
    'sousPeriodes': sousPeriodes.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [periodeScolaireId, ordre, statut, sousPeriodes];
}

/// Ligne sqflite `ref_cours_notation` — squelette de notation d'un cours mis en
/// cache (réf, lecture seule). L'arbre période/sous-période est sérialisé en JSON
/// dans [periodesJson] ; [periodes] le désérialise.
class RefCoursNotationRow extends Equatable {
  final String coursId;
  final String? classroomId;
  final String? brancheNom;
  final int effectif;
  final String periodesJson;
  final int? serverUpdatedAt;
  final int syncedAt;

  const RefCoursNotationRow({
    required this.coursId,
    this.classroomId,
    this.brancheNom,
    required this.effectif,
    required this.periodesJson,
    this.serverUpdatedAt,
    required this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Construit le squelette cache depuis le détail online (on ne retient que
  /// l'arbre + statut + effectif ; les évaluations/moyennes sont ignorées, elles
  /// sont recomposées depuis la table locale `evaluation`).
  factory RefCoursNotationRow.fromDetail(
    CoursNotationDetail detail, {
    required int syncedAt,
    int? serverUpdatedAt,
  }) {
    final periodes = detail.periodes
        .map(
          (p) => NotationPeriodeSkeleton(
            periodeScolaireId: p.periodeScolaireId,
            ordre: p.ordre,
            statut: p.statut.toApiValue(),
            sousPeriodes: p.sousPeriodes
                .map(
                  (sp) => NotationSousPeriodeSkeleton(
                    sousPeriodeId: sp.sousPeriodeId,
                    ordre: sp.ordre,
                    statut: sp.statut.toApiValue(),
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    return RefCoursNotationRow(
      coursId: detail.coursId,
      classroomId: detail.classroomId,
      brancheNom: detail.brancheNom,
      effectif: detail.effectif,
      periodesJson: jsonEncode(periodes.map((p) => p.toJson()).toList()),
      serverUpdatedAt: serverUpdatedAt,
      syncedAt: syncedAt,
    );
  }

  factory RefCoursNotationRow.fromMap(Map<String, Object?> map) =>
      RefCoursNotationRow(
        coursId: map['cours_id'] as String,
        classroomId: map['classroom_id'] as String?,
        brancheNom: map['branche_nom'] as String?,
        effectif: _asIntOrNull(map['effectif']) ?? 0,
        periodesJson: (map['periodes_json'] as String?) ?? '[]',
        serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
        syncedAt: _asIntOrNull(map['synced_at']) ?? 0,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'cours_id': coursId,
    'classroom_id': classroomId,
    'branche_nom': brancheNom,
    'effectif': effectif,
    'periodes_json': periodesJson,
    'server_updated_at': serverUpdatedAt,
    'synced_at': syncedAt,
  };

  /// L'arbre période désérialisé. Tolérant **par élément** : un JSON global
  /// illisible → liste vide ; une période/sous-période malformée est écartée
  /// sans annuler les autres.
  List<NotationPeriodeSkeleton> get periodes {
    final dynamic decoded;
    try {
      decoded = jsonDecode(periodesJson);
    } catch (_) {
      return const [];
    }
    return _lenient(decoded, NotationPeriodeSkeleton.fromJson);
  }

  @override
  List<Object?> get props => [
    coursId,
    classroomId,
    brancheNom,
    effectif,
    periodesJson,
    serverUpdatedAt,
    syncedAt,
  ];
}
