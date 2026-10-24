import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_totals_band.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les totaux du mois, tels que le serveur les compte : taux de présence
/// (hors vacataires à l'heure), heures de vacation — et leur montant, par
/// devise, pour qui lit la paie —, absences non justifiées, jours non pointés,
/// et ce que la tablette n'a pas encore envoyé.
class HrPresenceRecapTotals extends StatelessWidget {
  final HrAttendanceRecap recap;
  final int unsynced;

  const HrPresenceRecapTotals({
    super.key,
    required this.recap,
    required this.unsynced,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totals = recap.totals;
    final rate = totals.presenceRatePct;
    final hours = [
      PresenceLabels.hours(l10n, totals.workedMinutes),
      // Montant indicatif : la Paie paie ces heures le mois suivant (A1).
      for (final amount in totals.amounts ?? const [])
        MoneyFormat.format(amount),
    ].join(' · ');
    return PresenceTotalsBand(
      totals: [
        (
          l10n.presenceMarkTotalRate,
          rate == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(rate),
        ),
        (l10n.staffAttendanceTotalHours, hours),
        (l10n.presenceMarkTotalUnjustified, '${totals.unjustifiedAbsences}'),
        (l10n.presenceMarkTotalNotMarked, '${recap.unscored}'),
        if (unsynced > 0) (l10n.hrPresenceRecapUnsynced, '$unsynced'),
      ],
    );
  }
}
