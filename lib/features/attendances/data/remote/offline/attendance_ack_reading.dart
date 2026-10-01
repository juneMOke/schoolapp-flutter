import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart' show Clock;
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_response_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_line_wire.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';

/// Ce que la tablette retient de l'accusé de réception d'un appel : l'état
/// canonique du gagnant et le jeton LWW sur lequel se réancrer.
extension AttendanceAckReading on AttendanceAggregateResponseModel {
  /// Indexe l'état canonique du gagnant par élève. Sans identité : l'ACK ne
  /// transporte pas les libellés, et les fabriquer serait inventer de la donnée.
  Map<String, CanonicalAbsence> canonicalAbsences(Clock now) => {
    for (final ack in absences)
      ack.studentId: CanonicalAbsence(
        status: ack.status ?? AttendanceLineWire.absent,
        arrivalTime: AttendanceLineWire.arrival(ack.arrivalTime),
        lateMinutes: ack.lateMinutes,
        absenceReason: ack.absenceReason,
        absenceReasonNote: ack.absenceReasonNote,
        updatedAt: EpochIsoHelper.tryToEpochMs(ack.updatedAt) ?? now(),
      ),
  };

  /// Le jeton LWW sur lequel se réancrer après avoir PERDU l'arbitrage.
  ///
  /// `response.updatedAt` est la bonne réponse et passe donc en premier : le
  /// serveur porte désormais le jeton de l'état retenu sur le fil
  /// (`AttendanceAggregateResponse.session.updatedAt`).
  ///
  /// ⚠️ **Le repli reste, et il n'est pas décoratif.** Ce champ n'a pas toujours
  /// existé : `SessionRef` n'exposait que `id`, `serverUpdatedAt` et
  /// `expectedCount`, et un serveur pas encore monté de version répond toujours
  /// sans. Le parc ne bascule pas d'un bloc, la tablette parle à celui qu'elle
  /// trouve.
  ///
  /// Le repli d'origine était `now()` — l'horloge de la tablette, précisément
  /// celle qui retarde quand un `SUPERSEDED` survient. On se réancrait sur un
  /// jeton encore perdant, la correction suivante reperdait, et la journée ne
  /// pouvait plus jamais atterrir : la boucle que ce chemin existe pour fermer.
  ///
  /// À défaut du bon jeton, on prend donc le plus tardif de ce que la réponse
  /// porte encore : le commit Postgres du gagnant (`serverUpdatedAt`) et les
  /// `updatedAt` de ses absences, qui sont, eux, de vrais jetons client. Ce
  /// n'est pas exact — un gagnant dont l'horloge avançait a pu poser un jeton
  /// jusqu'à `ClientClockGuard.DEFAULT_TOLERANCE` (5 min) au-dessus de son
  /// commit — mais l'écart résiduel devient BORNÉ par cette tolérance, au lieu
  /// d'être celui, non borné, d'une tablette qui retarde.
  int adoptedLwwToken(Clock now) {
    var latest = EpochIsoHelper.tryToEpochMs(updatedAt);

    void keepLater(String? iso) {
      final candidate = EpochIsoHelper.tryToEpochMs(iso);
      if (candidate != null && (latest == null || candidate > latest!)) {
        latest = candidate;
      }
    }

    keepLater(serverUpdatedAt);
    for (final ack in absences) {
      keepLater(ack.updatedAt);
    }

    return latest ?? now();
  }
}
