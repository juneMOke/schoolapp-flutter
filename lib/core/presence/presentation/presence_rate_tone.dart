import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';

/// La teinte d'un taux de présence : vert dès [good], ambre dès [fair],
/// rouge en dessous (spec, récapitulatif du mois).
abstract final class PresenceRateTone {
  static const double good = 0.95;
  static const double fair = 0.85;

  static PresenceTone of(double rate) => PresenceTone.of(
    rate >= good
        ? PresenceStatus.present
        : rate >= fair
        ? PresenceStatus.late
        : PresenceStatus.absent,
  );

  /// « 97 % » arrondi à l'unité.
  static int percent(double rate) => (rate * 100).round();
}
