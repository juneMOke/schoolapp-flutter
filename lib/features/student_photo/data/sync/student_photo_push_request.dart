import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';

/// Le payload figé d'une entrée d'outbox `STUDENT_PHOTO` : un geste sur la
/// photo d'un élève.
///
/// [at] est la date du geste (prise au déclenchement, ou retrait), en UTC :
/// c'est elle que le serveur compare à celle qu'il garde. [sha256] désigne les
/// octets à envoyer (pose seulement) ; ils sont relus dans le magasin chiffré
/// au moment de l'envoi.
class StudentPhotoPushRequest {
  final String studentId;
  final StudentPhotoOp op;
  final String at;
  final String? sha256;
  final String authorId;

  const StudentPhotoPushRequest({
    required this.studentId,
    required this.op,
    required this.at,
    required this.authorId,
    this.sha256,
  });

  /// La partie `metadata` d'une pose.
  Map<String, dynamic> toMetadata() => {
    'takenAt': at,
    kOutboxAuthorIdKey: authorId,
  };

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'op': op.wire,
    'at': at,
    'sha256': ?sha256,
    kOutboxAuthorIdKey: authorId,
  };

  static StudentPhotoPushRequest? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final studentId = raw.text('studentId');
    final op = StudentPhotoOp.fromWire(raw.text('op'));
    final at = raw.text('at');
    final authorId = raw.text(kOutboxAuthorIdKey);
    final sha256 = raw.text('sha256');
    if (studentId == null || op == null || at == null || authorId == null) {
      return null;
    }
    if (op == StudentPhotoOp.put && sha256 == null) return null;
    return StudentPhotoPushRequest(
      studentId: studentId,
      op: op,
      at: at,
      sha256: sha256,
      authorId: authorId,
    );
  }
}
