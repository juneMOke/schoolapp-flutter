/// Réponse canonique du POST `/sync/classroom-transfers`
/// (`openapi_classroom_sync` 1.1.0 §ClassroomTransferResponse). Appliquée en une
/// transaction : repositionne le miroir `ref_classroom_members`, remplace les
/// compteurs des **deux** classes, passe le transfert SYNCED. `201` (créé) et
/// `200` (rejeu idempotent) portent les mêmes valeurs → même traitement.
class ClassroomTransferAck {
  final String transferId;
  final int? serverUpdatedAt;

  /// **Nullable par contrat** : sur un rejeu idempotent d'un transfert dont la
  /// ligne d'appartenance serveur a disparu, le serveur répond 200 avec
  /// `membership: null`. L'exiger non-nul faisait lever un `TypeError` au
  /// parsing → l'échec local était classé transitoire → 50 rejeux du même 200
  /// puis poison en `SYNC_ERROR`, sur une réponse pourtant valide.
  final ClassroomMembershipAck? membership;

  /// Les DEUX classes touchées (origine + destination), compteurs recalculés,
  /// autoritaires. Peut être vide sur un contrat dégradé → sens de panne géré
  /// par l'appelant (on ne scelle pas SYNCED si le miroir n'a pas été intégré).
  final List<ClassroomCountsAck> classrooms;

  const ClassroomTransferAck({
    required this.transferId,
    this.membership,
    this.serverUpdatedAt,
    this.classrooms = const [],
  });

  static int? _isoToEpochMs(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.millisecondsSinceEpoch;
  }

  factory ClassroomTransferAck.fromJson(Map<String, dynamic> json) {
    final transfer = (json['transfer'] as Map?)?.cast<String, dynamic>() ?? {};
    final classrooms = (json['classrooms'] as List?) ?? const [];
    return ClassroomTransferAck(
      transferId: transfer['id'] as String,
      serverUpdatedAt: _isoToEpochMs(transfer['serverUpdatedAt']),
      membership: switch (json['membership']) {
        final Map m => ClassroomMembershipAck.fromJson(
          m.cast<String, dynamic>(),
        ),
        _ => null,
      },
      classrooms: classrooms
          .map(
            (e) =>
                ClassroomCountsAck.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

/// Appartenance canonique après transfert (l'état dérivé de l'événement).
class ClassroomMembershipAck {
  final String? id;
  final String studentId;
  final String classroomId;
  final String academicYearId;
  final String? status;

  const ClassroomMembershipAck({
    required this.studentId,
    required this.classroomId,
    required this.academicYearId,
    this.id,
    this.status,
  });

  factory ClassroomMembershipAck.fromJson(Map<String, dynamic> json) =>
      ClassroomMembershipAck(
        id: json['id'] as String?,
        studentId: json['studentId'] as String,
        classroomId: json['classroomId'] as String,
        academicYearId: json['academicYearId'] as String,
        status: json['status'] as String?,
      );
}

/// Compteurs dérivés serveur (`COUNT`, jamais increment) d'une classe.
class ClassroomCountsAck {
  final String id;
  final int totalCount;
  final int femaleCount;
  final int maleCount;
  final int? capacity;

  const ClassroomCountsAck({
    required this.id,
    required this.totalCount,
    required this.femaleCount,
    required this.maleCount,
    this.capacity,
  });

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  factory ClassroomCountsAck.fromJson(Map<String, dynamic> json) =>
      ClassroomCountsAck(
        id: json['id'] as String,
        totalCount: _asInt(json['totalCount']),
        femaleCount: _asInt(json['femaleCount']),
        maleCount: _asInt(json['maleCount']),
        capacity: json['capacity'] == null ? null : _asInt(json['capacity']),
      );
}
