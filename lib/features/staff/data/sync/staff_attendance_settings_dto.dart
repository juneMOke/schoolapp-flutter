import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// Les réglages du Pointage, tels qu'ils sont mis en file puis poussés
/// (`PUT /api/v1/sync/staff-attendance-settings`, dernier écrit gagne) :
/// enveloppe `{ settings, authorId }`.
class StaffAttendanceSettingsRequestDto {
  /// `HH:mm`.
  final String startTime;
  final int toleranceMinutes;
  final String clientUpdatedAt;
  final String authorId;

  const StaffAttendanceSettingsRequestDto({
    required this.startTime,
    required this.toleranceMinutes,
    required this.clientUpdatedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'settings': {
      'startTime': startTime,
      'toleranceMinutes': toleranceMinutes,
      'clientUpdatedAt': clientUpdatedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  static StaffAttendanceSettingsRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    // L'ancienne clé est encore lue : une entrée mise en file avant le
    // contrat v3 ne doit pas devenir illisible.
    final settings = raw['settings'] ?? raw['staffAttendanceSettings'];
    if (settings is! Map) return null;
    final startTime = settings.text('startTime');
    final tolerance = settings.integer('toleranceMinutes');
    final clientUpdatedAt = settings.text('clientUpdatedAt');
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (startTime == null ||
        tolerance == null ||
        clientUpdatedAt == null ||
        authorId == null) {
      return null;
    }
    return StaffAttendanceSettingsRequestDto(
      startTime: startTime,
      toleranceMinutes: tolerance,
      clientUpdatedAt: clientUpdatedAt,
      authorId: authorId,
    );
  }
}

/// L'accusé : les réglages retenus par le serveur, qu'il ait retenu l'envoi
/// (`APPLIED`) ou gardé une écriture plus récente (`SUPERSEDED`).
class StaffAttendanceSettingsResponseDto {
  /// `HH:mm`, ou `null` si l'accusé ne le porte pas.
  final String? startTime;
  final int? toleranceMinutes;
  final String lwwOutcome;

  const StaffAttendanceSettingsResponseDto({
    required this.lwwOutcome,
    this.startTime,
    this.toleranceMinutes,
  });

  bool get superseded => lwwOutcome == 'SUPERSEDED';

  factory StaffAttendanceSettingsResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final settings = json['settings'];
    return StaffAttendanceSettingsResponseDto(
      startTime: settings is Map ? settings.text('startTime') : null,
      toleranceMinutes: settings is Map
          ? settings.integer('toleranceMinutes')
          : null,
      lwwOutcome: (json['lwwOutcome'] as String?) ?? 'APPLIED',
    );
  }
}
