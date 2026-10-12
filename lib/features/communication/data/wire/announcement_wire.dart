import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/features/communication/data/wire/audience_wire.dart';
import 'package:school_app_flutter/features/communication/data/wire/reach_wire.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';

/// Les communiqués et les modèles sur le fil. Lecture tolérante : une ligne
/// sans identifiant, sans statut connu ou sans audience lisible est écartée.
abstract final class AnnouncementWire {
  static Map<String, Object?> contentToJson(AnnouncementContent content) => {
    'category': content.category.wire,
    'title': content.title.trim(),
    'body': content.body.trim(),
    'audience': AudienceWire.toJson(content.audience),
    'channels': [for (final channel in content.channels) channel.wire],
  };

  static Announcement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final status = AnnouncementStatus.fromWire(raw.text('status'));
    final audience = AudienceWire.fromJson(raw['audience']);
    if (id == null || status == null || audience == null) return null;
    return Announcement(
      id: id,
      academicYearId: raw.text('academicYearId'),
      content: AnnouncementContent(
        category: AnnouncementCategory.fromWire(raw.text('category')),
        title: _plain(raw, 'title'),
        body: _plain(raw, 'body'),
        audience: audience,
        channels: [
          for (final wire in raw.texts('channels'))
            ?AnnouncementChannel.fromWire(wire),
        ],
      ),
      status: status,
      scheduledAt: _instant(raw, 'scheduledAt'),
      sentAt: _instant(raw, 'sentAt'),
      updatedAt: _instant(raw, 'updatedAt'),
      lastSendError: raw.text('lastSendError'),
      reachAtSend: ReachWire.fromJson(raw['reachAtSend']),
      version: raw.integer('version') ?? 0,
    );
  }

  static List<Announcement> listFromJson(Object? raw) => [
    if (raw is List)
      for (final item in raw) ?fromJson(item),
  ];

  static Map<String, Object?> templateToJson({
    required AnnouncementCategory category,
    required String title,
    required String body,
  }) => {'category': category.wire, 'title': title.trim(), 'body': body.trim()};

  static AnnouncementTemplate? templateFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    if (id == null) return null;
    return AnnouncementTemplate(
      id: id,
      category: AnnouncementCategory.fromWire(raw.text('category')),
      title: _plain(raw, 'title'),
      body: _plain(raw, 'body'),
    );
  }

  static List<AnnouncementTemplate> templatesFromJson(Object? raw) => [
    if (raw is List)
      for (final item in raw) ?templateFromJson(item),
  ];

  /// Le texte **tel qu'écrit** : les sauts de ligne du message comptent, seul
  /// le blanc des bords est retiré.
  static String _plain(Map<dynamic, dynamic> raw, String key) {
    final value = raw[key];
    return value is String ? value.trim() : '';
  }

  static DateTime? _instant(Map<dynamic, dynamic> raw, String key) {
    final value = raw.instant(key);
    return value == null ? null : DateTime.parse(value);
  }
}
