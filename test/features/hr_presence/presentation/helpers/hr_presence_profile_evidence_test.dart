import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_profile_evidence.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// La règle d'un profil chiffrée avec les comptes que le serveur a envoyés :
/// la tablette cite, elle ne rejuge pas.
void main() {
  final l10n = AppLocalizationsFr();

  HrAttendanceKpis kpis({
    int scored = 21,
    int presences = 18,
    int late = 2,
    int justified = 1,
    int unjustified = 2,
  }) {
    final presence = scored == 0 ? null : (100 * presences / scored).round();
    return HrAttendanceKpis(
      scored: scored,
      presences: presences,
      presenceRatePct: presence,
      absenceRatePct: presence == null ? null : 100 - presence,
      late: late,
      lateRatePct: scored == 0 ? null : (100 * late / scored).round(),
      lateMinutes: 0,
      punctualityPct: null,
      justifiedAbsences: justified,
      unjustifiedAbsences: unjustified,
      unscored: 0,
      workedMinutes: 0,
    );
  }

  test('absentéiste au seuil des 10 % : les absences et leur part', () {
    expect(
      HrPresenceProfileEvidence.of(l10n, PresenceProfile.absentee, kpis()),
      '3 absences sur 21 jours pointés, soit 14 % (seuil : 10 %)',
    );
  });

  test('absentéiste sous les 10 % (9,6 % s\'affiche 10 %) : les trois non '
      'justifiées, jugées sur les comptes', () {
    // 5 absences sur 52 jours : 9,6 %, arrondi à 10 % à l'écran.
    final year = kpis(scored: 52, presences: 47, justified: 2, unjustified: 3);
    expect(
      HrPresenceProfileEvidence.of(l10n, PresenceProfile.absentee, year),
      '3 absences non justifiées (seuil : 3)',
    );
  });

  test('retardataire : les retards et leur part', () {
    expect(
      HrPresenceProfileEvidence.of(
        l10n,
        PresenceProfile.late,
        kpis(presences: 21, late: 4, justified: 0, unjustified: 0),
      ),
      '4 retards sur 21 jours pointés, soit 19 % (seuil : plus de 15 %)',
    );
  });

  test('exemplaire, régulier : les deux taux ; non évalué : rien', () {
    final full = kpis(presences: 21, late: 1, justified: 0, unjustified: 0);
    expect(
      HrPresenceProfileEvidence.of(l10n, PresenceProfile.exemplary, full),
      'Présence 100 %, retards 5 % des jours pointés',
    );
    expect(
      HrPresenceProfileEvidence.of(
        l10n,
        PresenceProfile.notEvaluated,
        kpis(scored: 0, presences: 0, late: 0),
      ),
      isNull,
    );
  });

  test('la couverture : jours pointés sur jours de classe, sauf vacataire', () {
    expect(
      HrPresenceProfileEvidence.coverage(
        l10n,
        kpis(),
        classDays: 23,
        hourly: false,
      ),
      '21 jours pointés sur 23 jours de classe',
    );
    expect(
      HrPresenceProfileEvidence.coverage(
        l10n,
        kpis(),
        classDays: 23,
        hourly: true,
      ),
      isNull,
    );
  });
}
