import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Le geste local en attente sur la photo d'un élève.
enum StudentPhotoOp {
  put('PUT'),
  delete('DELETE');

  const StudentPhotoOp(this.wire);

  final String wire;

  static StudentPhotoOp? fromWire(String? value) {
    for (final op in values) {
      if (op.wire == value) return op;
    }
    return null;
  }
}

/// Une ligne de `student_photos`, lue telle quelle.
class StudentPhotoLocalModel {
  final Map<String, Object?> row;

  const StudentPhotoLocalModel(this.row);

  static const String table = 'student_photos';

  String get studentId => row['student_id']! as String;
  String get schoolId => row['school_id']! as String;

  /// Empreinte de la photo du serveur ; `null` = pas de photo.
  String? get sha256 => row['sha256'] as String?;
  String? get takenAt => row['taken_at'] as String?;

  StudentPhotoOp? get pendingOp =>
      StudentPhotoOp.fromWire(row['pending_op'] as String?);
  String? get pendingSha256 => row['pending_sha256'] as String?;
  String? get pendingAt => row['pending_at'] as String?;

  RecordSyncState get syncState =>
      RecordSyncState.fromDb(row['sync_status'] as String?);
  String? get syncError => row['sync_error'] as String?;

  String? cachedShaOf(StudentPhotoSize size) => switch (size) {
    StudentPhotoSize.thumb => row['cached_96_sha'] as String?,
    StudentPhotoSize.full => row['cached_512_sha'] as String?,
  };

  /// Le geste en attente, s'il porte encore sur cette ligne.
  bool holdsGesture(StudentPhotoOp op, String at) =>
      pendingOp == op && pendingAt == at;

  /// Ce que l'interface doit montrer : le geste en attente d'abord (la
  /// tablette qui l'a fait le voit aussitôt), sinon la photo du serveur.
  StudentPhotoRef toRef() {
    final op = pendingOp;
    final rejection = syncState == RecordSyncState.failed ? syncError : null;
    if (op == StudentPhotoOp.put && pendingSha256 != null) {
      return StudentPhotoRef(
        studentId: studentId,
        version: 'p:$pendingSha256',
        isPending: true,
      );
    }
    if (op == StudentPhotoOp.delete) {
      return StudentPhotoRef(studentId: studentId, isPending: true);
    }
    final sha = sha256;
    return StudentPhotoRef(
      studentId: studentId,
      version: sha == null ? null : 's:$sha',
      rejection: rejection,
    );
  }

  /// Colonne de la copie locale d'une taille.
  static String cachedColumnOf(StudentPhotoSize size) => switch (size) {
    StudentPhotoSize.thumb => 'cached_96_sha',
    StudentPhotoSize.full => 'cached_512_sha',
  };
}
