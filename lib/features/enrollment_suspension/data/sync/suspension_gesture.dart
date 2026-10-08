import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';

/// Les deux gestes d'une désactivation.
enum SuspensionGestureOp {
  suspend('SUSPEND'),
  reactivate('REACTIVATE');

  const SuspensionGestureOp(this.wire);

  final String wire;

  static SuspensionGestureOp? fromWire(Object? value) {
    for (final op in values) {
      if (op.wire == value) return op;
    }
    return null;
  }
}

/// Un geste tel qu'il est figé dans l'outbox : un élève par geste.
///
/// [id] est l'uuid du geste — celui de la période pour une désactivation, la
/// `reactivationId` pour une réactivation — et la clé d'idempotence serveur.
/// [studentId] et [academicYearId] ne partent pas sur le fil : ils servent la
/// sonde de dépendance et la projection sur le membre de classe.
class SuspensionGesture extends Equatable {
  final SuspensionGestureOp op;
  final String id;
  final String enrollmentId;
  final String studentId;
  final String academicYearId;

  /// Instant du geste sur la tablette, ISO-8601 UTC à la milliseconde.
  final String at;
  final String authorId;
  final SuspensionReason? reason;
  final String? precision;

  const SuspensionGesture({
    required this.op,
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.at,
    required this.authorId,
    this.reason,
    this.precision,
  });

  Map<String, Object?> toJson() => {
    'op': op.wire,
    'id': id,
    'enrollmentId': enrollmentId,
    'studentId': studentId,
    'academicYearId': academicYearId,
    'at': at,
    'authorId': authorId,
    if (reason != null) 'reason': reason!.wire,
    if (precision != null) 'precision': precision,
  };

  /// `null` si un champ obligatoire manque : l'entrée est illisible.
  static SuspensionGesture? tryParse(Object? json) {
    if (json is! Map) return null;
    final op = SuspensionGestureOp.fromWire(json['op']);
    String? text(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    final id = text('id');
    final enrollmentId = text('enrollmentId');
    final studentId = text('studentId');
    final yearId = text('academicYearId');
    final at = text('at');
    final authorId = text('authorId');
    if (op == null ||
        id == null ||
        enrollmentId == null ||
        studentId == null ||
        yearId == null ||
        at == null ||
        authorId == null) {
      return null;
    }
    return SuspensionGesture(
      op: op,
      id: id,
      enrollmentId: enrollmentId,
      studentId: studentId,
      academicYearId: yearId,
      at: at,
      authorId: authorId,
      reason: SuspensionReason.fromWire(text('reason')),
      precision: text('precision'),
    );
  }

  @override
  List<Object?> get props => [
    op,
    id,
    enrollmentId,
    studentId,
    academicYearId,
    at,
    authorId,
    reason,
    precision,
  ];
}
