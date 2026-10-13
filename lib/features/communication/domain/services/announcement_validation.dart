import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';

/// Les champs que le serveur nomme dans `details.fields`, et que l'éditeur
/// marque en faute.
enum AnnouncementField {
  title('title'),
  body('body'),
  audience('audience'),
  channels('channels'),
  scheduledAt('scheduledAt');

  const AnnouncementField(this.wire);

  final String wire;

  static AnnouncementField? fromWire(Object? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

/// Ce qui empêche de programmer ou d'envoyer, jugé sur la tablette avant tout
/// appel : les mêmes règles que le serveur, pour que l'erreur s'affiche sous le
/// champ et non dans un bandeau.
enum AnnouncementIssue {
  titleMissing(AnnouncementField.title),
  bodyMissing(AnnouncementField.body),
  unknownVariable(AnnouncementField.body),
  amountOutsideOverdue(AnnouncementField.body),
  amountInTitle(AnnouncementField.title),
  audienceEmpty(AnnouncementField.audience),
  noChannel(AnnouncementField.channels),
  scheduleNotFuture(AnnouncementField.scheduledAt);

  const AnnouncementIssue(this.field);

  final AnnouncementField field;
}

abstract final class AnnouncementValidation {
  /// Un brouillon s'enregistre dès qu'il a un titre **ou** un message.
  static bool canSaveDraft(AnnouncementContent content) =>
      content.title.trim().isNotEmpty || content.body.trim().isNotEmpty;

  /// Ce qui manque pour programmer ou envoyer [content] ; vide si rien.
  ///
  /// [scheduledAt] n'est jugé que pour une programmation : il doit être
  /// strictement postérieur à [now].
  static List<AnnouncementIssue> issuesOf(
    AnnouncementContent content, {
    DateTime? scheduledAt,
    DateTime? now,
  }) {
    final body = content.body;
    return [
      if (content.title.trim().isEmpty) AnnouncementIssue.titleMissing,
      if (body.trim().isEmpty) AnnouncementIssue.bodyMissing,
      if (AnnouncementVariables.unknownIn('${content.title} $body').isNotEmpty)
        AnnouncementIssue.unknownVariable,
      if (amountMisplaced(content)) AnnouncementIssue.amountOutsideOverdue,
      if (amountInTitle(content)) AnnouncementIssue.amountInTitle,
      if (content.audience.isEmpty) AnnouncementIssue.audienceEmpty,
      if (content.channels.isEmpty) AnnouncementIssue.noChannel,
      if (scheduledAt != null &&
          now != null &&
          !scheduledAt.toUtc().isAfter(now.toUtc()))
        AnnouncementIssue.scheduleNotFuture,
    ];
  }

  /// `{montant}` dans le message hors du mode Retards de paiement : le serveur
  /// le refuse, et l'éditeur l'annonce en ambre dès qu'il apparaît.
  static bool amountMisplaced(AnnouncementContent content) =>
      content.audience is! OverdueAudience &&
      AnnouncementVariables.usedIn(
        content.body,
      ).contains(AnnouncementVariable.amount);

  /// `{montant}` dans le titre, quel que soit le mode : le titre part en clair
  /// dans le WhatsApp, le montant reste derrière le lien. Refusé dès le
  /// brouillon.
  static bool amountInTitle(AnnouncementContent content) =>
      AnnouncementVariables.usedIn(
        content.title,
      ).contains(AnnouncementVariable.amount);
}
