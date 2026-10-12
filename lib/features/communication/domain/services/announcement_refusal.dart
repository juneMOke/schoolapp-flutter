import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';

/// Un refus métier du serveur : un 422 dont le `detailCode` vaut
/// `ANNOUNCEMENT_*`. Jamais un 409 — la tablette rejoue les 409.
enum AnnouncementRefusal {
  /// Envoyé, annulé, ou programmé dont l'heure est passée.
  notEditable('ANNOUNCEMENT_NOT_EDITABLE'),

  /// Un champ manque ; `details.fields` les nomme.
  incomplete('ANNOUNCEMENT_INCOMPLETE'),
  scheduleNotFuture('ANNOUNCEMENT_SCHEDULE_NOT_FUTURE'),
  unknownVariable('ANNOUNCEMENT_UNKNOWN_VARIABLE'),
  amountOutsideOverdue('ANNOUNCEMENT_AMOUNT_OUTSIDE_OVERDUE'),

  /// Le gabarit WhatsApp de l'école n'est pas encore activé.
  channelDisabled('ANNOUNCEMENT_CHANNEL_DISABLED'),

  /// L'audience résolue à l'envoi ne donne aucun message joignable.
  noRecipient('ANNOUNCEMENT_NO_RECIPIENT'),

  /// Quelqu'un l'a modifié depuis la lecture : il faut relire.
  stale('ANNOUNCEMENT_STALE');

  const AnnouncementRefusal(this.detailCode);

  final String detailCode;

  /// Le refus porté par [failure], `null` si ce n'en est pas un — ou si le
  /// serveur nomme un code que l'application ne connaît pas encore.
  static AnnouncementRefusal? of(Failure failure) {
    if (failure is! ApiValidationFailure) return null;
    for (final value in values) {
      if (value.detailCode == failure.detailCode) return value;
    }
    return null;
  }

  /// Les champs que le serveur désigne (`details.fields`), connus de
  /// l'application ; à défaut, celui que le code désigne à lui seul.
  static Set<AnnouncementField> fieldsOf(Failure failure) {
    final refusal = of(failure);
    final details = failure is ApiValidationFailure ? failure.details : null;
    final named = details == null ? null : details['fields'];
    final fields = {
      if (named is List)
        for (final raw in named) ?AnnouncementField.fromWire(raw),
    };
    if (fields.isNotEmpty) return fields;
    return switch (refusal) {
      AnnouncementRefusal.scheduleNotFuture => {AnnouncementField.scheduledAt},
      AnnouncementRefusal.unknownVariable ||
      AnnouncementRefusal.amountOutsideOverdue => {AnnouncementField.body},
      _ => const {},
    };
  }
}
