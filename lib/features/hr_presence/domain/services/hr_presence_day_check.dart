import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';

/// Ce que la tablette sait d'un jour que la fiche (le serveur) montre.
enum HrPresenceDayAgreement {
  /// La tablette a ce jour tel que le serveur le connaît (ou ni l'un ni
  /// l'autre ne l'a pointé) : on peut le corriger.
  same,

  /// La tablette a écrit ce jour et ne l'a pas encore envoyé (ou l'envoi a
  /// été refusé) : sa ligne est la plus récente, on peut la reprendre.
  localAhead,

  /// Le serveur a un pointage que la tablette n'a pas reçu.
  missing,

  /// La tablette et le serveur disent deux choses différentes.
  divergent;

  /// Corriger depuis la fiche ne part que d'une ligne sûre : sinon l'éditeur
  /// partirait d'une ligne vierge ou périmée, et écraserait le serveur.
  bool get editable => this == same || this == localAhead;
}

/// Confronte la ligne de la tablette au jour du serveur, sans rien écrire.
///
/// La fiche lit le serveur (route 2), l'écriture part de la tablette : on ne
/// corrige un jour qu'après avoir vérifié qu'ils parlent de la même ligne.
/// Jamais de ligne locale fabriquée à partir de la réponse du serveur.
abstract final class HrPresenceDayCheck {
  static HrPresenceDayAgreement of({
    required HrAttendanceDay server,
    required StaffAttendanceRecord? local,
  }) {
    if (local == null) {
      return server.status == PresenceStatus.none
          ? HrPresenceDayAgreement.same
          : HrPresenceDayAgreement.missing;
    }
    if (local.syncState != RecordSyncState.synced) {
      return HrPresenceDayAgreement.localAhead;
    }
    return matches(server, local)
        ? HrPresenceDayAgreement.same
        : HrPresenceDayAgreement.divergent;
  }

  /// Le jour du serveur et la ligne de la tablette disent-ils la même chose ?
  static bool matches(HrAttendanceDay server, StaffAttendanceRecord local) =>
      server.status == local.status &&
      ClockTime.tryParse(server.arrival) == local.arrival &&
      ClockTime.tryParse(server.departure) == local.departure &&
      server.lateMinutes == local.lateMinutes &&
      server.workedMinutes == (local.workedMinutes ?? 0) &&
      server.reason == local.justification?.reason &&
      _blankToNull(server.note) == _blankToNull(local.justification?.note);

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
