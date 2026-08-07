import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Une entrée de la file d'écriture différée (outbox). Chaque entrée = un
/// agrégat métier figé (payload JSON), poussé de façon idempotente au serveur
/// par le [SyncEngine] via le handler correspondant à [aggregateType].
///
/// L'idempotence repose sur [aggregateId] (= id métier honoré serveur, ex.
/// `enrollment.id` ou `payment.client_uuid`) : un rejeu ne duplique jamais.
class OutboxEntry extends Equatable {
  /// Identifiant unique de l'ENTRÉE (uuid client). PK de la table.
  final String id;

  /// Type d'agrégat : ENROLLMENT | PAYMENT | ATTENDANCE | DISCIPLINARY_CASE |
  /// CLASSROOM_REASSIGN … (routage vers le handler de dispatch).
  final String aggregateType;

  /// Clé d'idempotence métier (id honoré serveur).
  final String aggregateId;

  /// Nature de l'opération (create/update/upsert).
  final OutboxOperation operation;

  /// Payload figé (JSON encodé) au moment de la confirmation locale.
  final String payload;

  /// Garde-fou tenant : n'autorise le flush que pour l'école authentifiée
  /// (empêche un replay cross-école après reconnexion). Nullable si mono-tenant.
  final String? schoolId;

  /// Statut technique de l'entrée (pending/acked/sync_error).
  final OutboxStatus status;

  /// Nombre de tentatives de push (backoff exponentiel).
  final int attempts;

  /// Epoch ms de création — clé d'ordonnancement FIFO du flush.
  final int createdAt;

  /// Epoch ms avant lequel l'entrée n'est pas re-tentée (barrière de backoff).
  final int nextAttemptAt;

  /// Dernière erreur rencontrée (diagnostic UI / logs).
  final String? lastError;

  const OutboxEntry({
    required this.id,
    required this.aggregateType,
    required this.aggregateId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.schoolId,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    this.nextAttemptAt = 0,
    this.lastError,
  });

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'aggregate_type': aggregateType,
    'aggregate_id': aggregateId,
    'operation': operation.toDbValue(),
    'payload': payload,
    'school_id': schoolId,
    'status': status.toDbValue(),
    'attempts': attempts,
    'created_at': createdAt,
    'next_attempt_at': nextAttemptAt,
    'last_error': lastError,
  };

  factory OutboxEntry.fromMap(Map<String, Object?> map) => OutboxEntry(
    id: map['id'] as String,
    aggregateType: map['aggregate_type'] as String,
    aggregateId: map['aggregate_id'] as String,
    operation: OutboxOperation.fromDbValue(map['operation'] as String?),
    payload: map['payload'] as String,
    schoolId: map['school_id'] as String?,
    status: OutboxStatus.fromDbValue(map['status'] as String?),
    attempts: (map['attempts'] as int?) ?? 0,
    createdAt: (map['created_at'] as int?) ?? 0,
    nextAttemptAt: (map['next_attempt_at'] as int?) ?? 0,
    lastError: map['last_error'] as String?,
  );

  OutboxEntry copyWith({
    OutboxStatus? status,
    int? attempts,
    int? nextAttemptAt,
    String? lastError,
  }) => OutboxEntry(
    id: id,
    aggregateType: aggregateType,
    aggregateId: aggregateId,
    operation: operation,
    payload: payload,
    schoolId: schoolId,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError ?? this.lastError,
  );

  @override
  List<Object?> get props => [
    id,
    aggregateType,
    aggregateId,
    operation,
    payload,
    schoolId,
    status,
    attempts,
    createdAt,
    nextAttemptAt,
    lastError,
  ];
}
