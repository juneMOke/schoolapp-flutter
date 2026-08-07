import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Ligne sqflite `attendance_sessions` (racine d'agrégat de l'appel, contrat
/// 1.2.0). Sa seule existence pour un `(classroom, date, année)` signifie
/// « appel fait » ; son absence signifie « appel non fait » (jamais présent).
///
/// - `updatedAt` (epoch ms, horloge client) arbitre le last-write-wins et est
///   rebumpé à CHAQUE modification de l'agrégat (même quand seule une absence
///   change), sinon le pull paginé sur la session passe à côté.
/// - `expectedCount` = snapshot serveur du roster ACTIF (dénominateur des taux
///   agrégés back-office) ; informatif côté tablette.
/// - `serverUpdatedAt` (ISO String) = visibilité serveur reçue au pull ; le
///   curseur de pagination lui-même reste opaque dans `sync_meta`.
class AttendanceSessionRow extends Equatable {
  final String id;
  final String classroomId;

  /// 'yyyy-MM-dd'.
  final String attendanceDate;
  final String academicYearId;
  final int? expectedCount;

  /// Heure métier de l'appel (epoch ms).
  final int? takenAt;
  final String? takenBy;

  /// Arbitre du last-write-wins (epoch ms, horloge client).
  final int updatedAt;

  /// Visibilité serveur (ISO-8601), reçue au pull. Nul tant que non synchronisé.
  final String? serverUpdatedAt;
  final int? version;
  final String syncStatus;
  final int? syncedAt;

  const AttendanceSessionRow({
    required this.id,
    required this.classroomId,
    required this.attendanceDate,
    required this.academicYearId,
    this.expectedCount,
    this.takenAt,
    this.takenBy,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.version,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory AttendanceSessionRow.fromMap(Map<String, Object?> map) =>
      AttendanceSessionRow(
        id: map['id'] as String,
        classroomId: map['classroom_id'] as String,
        attendanceDate: map['attendance_date'] as String,
        academicYearId: map['academic_year_id'] as String,
        expectedCount: _asIntOrNull(map['expected_count']),
        takenAt: _asIntOrNull(map['taken_at']),
        takenBy: map['taken_by'] as String?,
        updatedAt: _asIntOrNull(map['updated_at']) ?? 0,
        serverUpdatedAt: map['server_updated_at'] as String?,
        version: _asIntOrNull(map['version']),
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncedAt: _asIntOrNull(map['synced_at']),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'classroom_id': classroomId,
    'attendance_date': attendanceDate,
    'academic_year_id': academicYearId,
    'expected_count': expectedCount,
    'taken_at': takenAt,
    'taken_by': takenBy,
    'updated_at': updatedAt,
    'server_updated_at': serverUpdatedAt,
    'version': version,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
  };

  bool get isSynced => SyncState.fromDbValue(syncStatus).isSynced;

  /// Copie en substituant l'`id` (id = transport, clé naturelle = vérité :
  /// on conserve l'id local existant quand la clé naturelle est déjà connue).
  AttendanceSessionRow copyWithId(String id) => AttendanceSessionRow(
    id: id,
    classroomId: classroomId,
    attendanceDate: attendanceDate,
    academicYearId: academicYearId,
    expectedCount: expectedCount,
    takenAt: takenAt,
    takenBy: takenBy,
    updatedAt: updatedAt,
    serverUpdatedAt: serverUpdatedAt,
    version: version,
    syncStatus: syncStatus,
    syncedAt: syncedAt,
  );

  @override
  List<Object?> get props => [
    id,
    classroomId,
    attendanceDate,
    academicYearId,
    expectedCount,
    takenAt,
    takenBy,
    updatedAt,
    serverUpdatedAt,
    version,
    syncStatus,
    syncedAt,
  ];
}
