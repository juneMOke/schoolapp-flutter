import 'dart:convert';

import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';

/// La copie déposée, entre le fil, la table `evaluation_depot` et le domaine.
abstract final class DepotCopieRow {
  /// Les copies du champ `depots` d'une évaluation ; `null` si la vue ne le
  /// porte pas — ce n'est pas « aucune copie », et la tablette garde alors
  /// celles qu'elle connaît. Une copie illisible est écartée.
  static List<DepotCopie>? listFromJson(Object? json) {
    if (json is! List) return null;
    return [for (final raw in json) ?_fromJson(raw)];
  }

  static DepotCopie? _fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final studentId = raw['studentId'];
    if (id is! String || studentId is! String) return null;
    final declared = raw['fichiers'] is List
        ? (raw['fichiers'] as List).length
        : 0;
    final fichiers = _fichiers(raw['fichiers']);
    return DepotCopie(
      id: id,
      studentId: studentId,
      depositedAt: DateTime.tryParse(raw['depositedAt'] as String? ?? ''),
      enRetard: raw['enRetard'] == true,
      fichiers: fichiers,
      pagesEcartees: declared - fichiers.length,
    );
  }

  /// Les pages, triées par ordre ; une page mal décrite est écartée.
  static List<DepotFichier> _fichiers(Object? json) {
    if (json is! List) return const [];
    final pages = [
      for (final raw in json)
        if (raw is Map<String, dynamic>)
          if (raw['id'] case final String id)
            if (AttachmentRef.tryParse(raw) case final ref?)
              DepotFichier(
                id: id,
                ordre: (raw['ordre'] as num?)?.toInt() ?? 0,
                ref: ref,
              ),
    ]..sort((a, b) => a.ordre.compareTo(b.ordre));
    return pages;
  }

  static Map<String, Object?> toMap(String evaluationId, DepotCopie depot) => {
    'id': depot.id,
    'evaluation_id': evaluationId,
    'student_id': depot.studentId,
    'deposited_at': depot.depositedAt?.toUtc().toIso8601String(),
    'en_retard': depot.enRetard ? 1 : 0,
    'pages_ecartees': depot.pagesEcartees,
    'fichiers_json': jsonEncode([
      for (final page in depot.fichiers)
        {
          'id': page.id,
          'ordre': page.ordre,
          'nom': page.ref.name,
          'mimeType': page.ref.mimeType,
          'sizeBytes': page.ref.sizeBytes,
          'sha256': page.ref.sha256,
        },
    ]),
  };

  static DepotCopie fromMap(Map<String, Object?> map) => DepotCopie(
    id: map['id']! as String,
    studentId: map['student_id']! as String,
    depositedAt: DateTime.tryParse(map['deposited_at'] as String? ?? ''),
    enRetard: map['en_retard'] == 1,
    fichiers: _fichiers(_decode(map['fichiers_json'])),
    pagesEcartees: (map['pages_ecartees'] as int?) ?? 0,
  );

  static Object? _decode(Object? column) {
    if (column is! String) return null;
    try {
      return jsonDecode(column);
    } catch (_) {
      return null;
    }
  }
}
