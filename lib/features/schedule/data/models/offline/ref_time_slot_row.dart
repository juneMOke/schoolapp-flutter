import 'package:equatable/equatable.dart';

/// Ligne sqflite `ref_time_slots` — trame horaire de l'école. **Référence pure,
/// lecture seule** : jamais écrite localement, uniquement peuplée par le pull.
/// `startTime`/`endTime` en TEXT « HH:mm ». `slotOrder` = ordre métier
/// d'affichage (le pull keyset trie serveur par `server_updated_at`, le client
/// re-trie par `slotOrder`).
class RefTimeSlotRow extends Equatable {
  final String id;
  final int slotOrder;
  final String startTime;
  final String endTime;
  final String? label;

  /// La grille du créneau (v84) : un cycle désigne sa grille, deux grilles
  /// coexistent dans une école (EDT-R1). `null` avant EDT-1 côté serveur.
  final String? timeGridId;
  final int? serverUpdatedAt;
  final int syncedAt;

  const RefTimeSlotRow({
    required this.id,
    required this.slotOrder,
    required this.startTime,
    required this.endTime,
    this.label,
    this.timeGridId,
    this.serverUpdatedAt,
    required this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory RefTimeSlotRow.fromMap(Map<String, Object?> map) => RefTimeSlotRow(
    id: map['id'] as String,
    slotOrder: _asIntOrNull(map['slot_order']) ?? 0,
    startTime: map['start_time'] as String,
    endTime: map['end_time'] as String,
    label: map['label'] as String?,
    timeGridId: map['time_grid_id'] as String?,
    serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
    syncedAt: _asIntOrNull(map['synced_at']) ?? 0,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'slot_order': slotOrder,
    'start_time': startTime,
    'end_time': endTime,
    'label': label,
    'time_grid_id': timeGridId,
    'server_updated_at': serverUpdatedAt,
    'synced_at': syncedAt,
  };

  @override
  List<Object?> get props => [
    id,
    slotOrder,
    startTime,
    endTime,
    label,
    timeGridId,
    serverUpdatedAt,
    syncedAt,
  ];
}
