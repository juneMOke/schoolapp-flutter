import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';

/// Ce que l'école écrit : la seule partie d'un communiqué que `POST` et `PUT`
/// transportent. Le statut, lui, ne bouge que par un geste.
class AnnouncementContent extends Equatable {
  /// Plafonds du serveur, en caractères.
  static const int titleMaxLength = 80;
  static const int bodyMaxLength = 1000;

  final AnnouncementCategory category;
  final String title;
  final String body;
  final AnnouncementAudience audience;
  final List<AnnouncementChannel> channels;

  const AnnouncementContent({
    this.category = AnnouncementCategory.info,
    this.title = '',
    this.body = '',
    this.audience = const SchoolAudience(),
    this.channels = const [AnnouncementChannel.whatsapp],
  });

  AnnouncementContent copyWith({
    AnnouncementCategory? category,
    String? title,
    String? body,
    AnnouncementAudience? audience,
    List<AnnouncementChannel>? channels,
  }) => AnnouncementContent(
    category: category ?? this.category,
    title: title ?? this.title,
    body: body ?? this.body,
    audience: audience ?? this.audience,
    channels: channels ?? this.channels,
  );

  /// Le même contenu **tel que le serveur le garde** : titre et message
  /// rognés, canaux sans ordre. Deux contenus « égaux » ici n'ont pas besoin
  /// d'un `PUT`.
  bool sameAs(AnnouncementContent other) =>
      category == other.category &&
      title.trim() == other.title.trim() &&
      body.trim() == other.body.trim() &&
      audience == other.audience &&
      channels.toSet().length == other.channels.toSet().length &&
      channels.toSet().containsAll(other.channels);

  @override
  List<Object?> get props => [category, title, body, audience, channels];
}
