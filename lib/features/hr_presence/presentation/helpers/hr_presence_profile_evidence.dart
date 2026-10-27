import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La règle d'un profil avec les chiffres de l'agent : « 3 absences sur 21
/// jours pointés, soit 14 % (seuil : 10 %) », puis ce que la période a
/// pointé.
///
/// La tablette ne recalcule pas le profil — le serveur l'a jugé sur ses
/// comptes ; elle cite seulement les chiffres qu'il lui a envoyés, pour qu'un
/// badge « Absentéiste » se lise avec sa raison.
abstract final class HrPresenceProfileEvidence {
  /// Le seuil d'absences du serveur (`AttendanceProfile.ABSENCE_PCT`).
  static const _absencePct = 10;

  /// `null` : rien à chiffrer (période sans jour pointé).
  static String? of(
    AppLocalizations l10n,
    PresenceProfile profile,
    HrAttendanceKpis kpis,
  ) {
    final presence = kpis.presenceRatePct;
    final late = kpis.lateRatePct;
    final absent = kpis.absenceRatePct;
    final absences = kpis.justifiedAbsences + kpis.unjustifiedAbsences;
    return switch (profile) {
      PresenceProfile.notEvaluated => null,
      // Le seuil en pourcentage passe d'abord : c'est lui que l'on cite quand
      // les deux règles tiennent. Jugé sur les comptes, comme le serveur :
      // 9,6 % s'affiche « 10 % » mais n'atteint pas le seuil.
      PresenceProfile.absentee
          when absent != null && 100 * absences >= _absencePct * kpis.scored =>
        l10n.hrPresenceEvidenceAbsences(absences, kpis.scored, absent),
      PresenceProfile.absentee => l10n.hrPresenceEvidenceUnjustified(
        kpis.unjustifiedAbsences,
      ),
      PresenceProfile.late when late != null => l10n.hrPresenceEvidenceLates(
        kpis.late,
        kpis.scored,
        late,
      ),
      _ when presence != null && late != null => l10n.hrPresenceEvidenceRates(
        presence,
        late,
      ),
      _ => null,
    };
  }

  /// « 21 jours pointés sur 23 jours de classe » ; `null` pour un vacataire
  /// payé à l'heure, qui n'est pas attendu chaque jour de classe.
  static String? coverage(
    AppLocalizations l10n,
    HrAttendanceKpis kpis, {
    required int classDays,
    required bool hourly,
  }) => hourly || classDays == 0
      ? null
      : l10n.hrPresenceEvidenceCoverage(kpis.scored, classDays);
}
