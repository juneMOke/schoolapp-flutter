import 'package:school_app_flutter/core/offline/lww_outcome.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_fiche_codec.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/push/programme_push_op.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';

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
  String? get clientUpdatedAt => pushString(fiche['clientUpdatedAt']);

  Map<String, Object?> toJson() => {
    'op': op.wireValue,
    'chapitreId': chapitreId,
    'coursId': coursId,
    'fiche': fiche,
  };

  static ChapitreFichePayload? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final op = ProgrammePushOp.fromWire(raw['op']);
    final chapitreId = pushString(raw['chapitreId']);
    final coursId = pushString(raw['coursId']);
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
      ignored: LwwOutcome.fromWire(json['lwwOutcome']) == LwwOutcome.superseded,
    );
  }
}
