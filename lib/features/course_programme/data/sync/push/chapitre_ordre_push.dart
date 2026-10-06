import 'package:school_app_flutter/features/course_programme/data/sync/push/programme_push_op.dart';

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
    final coursId = pushString(raw['coursId']);
    final ids = raw['chapitreIds'];
    final at = pushString(raw['clientUpdatedAt']);
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
