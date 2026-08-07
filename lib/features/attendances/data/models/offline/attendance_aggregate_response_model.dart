import 'package:equatable/equatable.dart';

/// Réponse du serveur au push d'un agrégat d'appel (`POST /sync/attendance`).
///
/// On ne consomme que ce dont la tablette a besoin pour se réaligner (AG-3) :
/// l'id canonique + `serverUpdatedAt` (visibilité) + `expectedCount` (snapshot
/// roster serveur, informatif) + `lwwOutcome`.
///
/// Le `SUPERSEDED` n'a rien d'un cas d'école en mono-tablette : il survient dès
/// que l'`updated_at` local vient d'un pull au temps serveur en avance sur
/// l'horloge du device, ou qu'une saisie back-office a touché la même journée.
/// C'est pourquoi la réponse porte l'état canonique des absences du gagnant :
/// [AttendanceOutboxHandler] l'adopte (`adoptCanonicalDay`) puis acquitte, au
/// lieu de sceller la journée sur nos propres valeurs perdantes.
class AttendanceAggregateResponseModel extends Equatable {
  final String sessionId;
  final String? serverUpdatedAt;
  final int? expectedCount;

  /// `APPLIED` (écriture retenue) | `SUPERSEDED` (un état plus récent existait).
  final String lwwOutcome;

  /// Jeton LWW de l'état **gagnant** (`client_updated_at`), nécessaire pour
  /// réancrer l'horloge locale : sans lui, la tablette resterait sur son propre
  /// jeton perdant et reperdrait tous les arbitrages suivants.
  final String? updatedAt;

  /// État canonique des absences du gagnant. Le contrat le renvoie précisément
  /// pour que le client s'y réaligne — c'est la seule façon de sortir d'un
  /// `SUPERSEDED` sans divergence.
  final List<AttendanceAbsenceAck> absences;

  const AttendanceAggregateResponseModel({
    required this.sessionId,
    this.serverUpdatedAt,
    this.expectedCount,
    required this.lwwOutcome,
    this.updatedAt,
    this.absences = const [],
  });

  factory AttendanceAggregateResponseModel.fromJson(Map<String, dynamic> json) {
    final session = (json['session'] as Map<String, dynamic>?) ?? const {};
    // Parsing tolérant : une absence illisible ne doit pas faire échouer tout
    // l'ACK (le push a réussi côté serveur, le perdre serait pire).
    final rawAbsences = (json['absences'] as List?) ?? const [];
    return AttendanceAggregateResponseModel(
      sessionId: session['id'] as String? ?? '',
      serverUpdatedAt: session['serverUpdatedAt'] as String?,
      expectedCount: (session['expectedCount'] as num?)?.toInt(),
      lwwOutcome: json['lwwOutcome'] as String? ?? 'APPLIED',
      updatedAt: session['updatedAt'] as String?,
      absences: rawAbsences
          .whereType<Map>()
          .map(
            (e) => AttendanceAbsenceAck.tryFromJson(e.cast<String, dynamic>()),
          )
          .whereType<AttendanceAbsenceAck>()
          .toList(growable: false),
    );
  }

  bool get isSuperseded => lwwOutcome == 'SUPERSEDED';

  @override
  List<Object?> get props => [
    sessionId,
    serverUpdatedAt,
    expectedCount,
    lwwOutcome,
    updatedAt,
    absences,
  ];
}

/// Une absence telle que le serveur la détient après arbitrage.
class AttendanceAbsenceAck extends Equatable {
  final String studentId;
  final String? absenceReason;
  final String? absenceReasonNote;
  final String? updatedAt;

  const AttendanceAbsenceAck({
    required this.studentId,
    this.absenceReason,
    this.absenceReasonNote,
    this.updatedAt,
  });

  static AttendanceAbsenceAck? tryFromJson(Map<String, dynamic> json) {
    final studentId = json['studentId'] as String?;
    if (studentId == null || studentId.isEmpty) return null;
    return AttendanceAbsenceAck(
      studentId: studentId,
      absenceReason: json['absenceReason'] as String?,
      absenceReasonNote: json['absenceReasonNote'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    absenceReason,
    absenceReasonNote,
    updatedAt,
  ];
}
