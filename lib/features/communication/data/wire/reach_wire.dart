import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';

abstract final class ReachWire {
  /// `null` pour une portée illisible : l'encart dit alors qu'il ne sait pas,
  /// plutôt que d'afficher zéro.
  static AnnouncementReach? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final messages = raw.integer('messages');
    final reachable = raw.integer('reachableMessages');
    if (messages == null || reachable == null) return null;
    return AnnouncementReach(
      students: raw.integer('students') ?? 0,
      guardians: raw.integer('guardians') ?? 0,
      messages: messages,
      reachableMessages: reachable,
      guardiansWithoutPhone: raw.integer('guardiansWithoutPhone') ?? 0,
      studentsUnreachable: raw.integer('studentsUnreachable') ?? 0,
      whatsappEnabled: raw.flag('whatsappEnabled'),
    );
  }
}
