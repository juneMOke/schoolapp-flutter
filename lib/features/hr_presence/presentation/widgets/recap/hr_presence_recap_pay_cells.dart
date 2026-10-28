import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cellules d'argent d'une ligne du récapitulatif, alignées à droite :
/// le brut prévu, la retenue d'absence, le brut après absences. Un montant
/// et, dessous, d'où il vient.
abstract final class HrPresenceRecapPayCells {
  static String _money(int cents, String currency) =>
      MoneyFormat.format(Money(cents, currency));

  /// Le brut prévu ; pour un vacataire à l'heure, « 20 h × 8 $ » dessous.
  static Widget gross(BuildContext context, HrAttendanceRecapRow row) {
    final l10n = AppLocalizations.of(context)!;
    final pay = row.pay;
    if (pay == null) return _none(l10n);
    final rate = pay.hourlyRateInCents;
    return _amount(
      _money(pay.grossInCents, pay.currency),
      detail: rate == null
          ? null
          : l10n.hrPresenceRecapHourlyRate(
              PresenceLabels.hours(l10n, row.workedMinutes),
              _money(rate, pay.currency),
            ),
    );
  }

  /// « − 65,45 $ » et « 3 j × 21,82 $ » ; « payé à l'heure » pour un
  /// vacataire ; un tiret quand rien n'est retenu. Le taux journalier est un
  /// affichage : seule la retenue fait foi.
  static Widget deduction(BuildContext context, HrAttendanceRecapRow row) {
    final l10n = AppLocalizations.of(context)!;
    final pay = row.pay;
    if (pay == null) return _none(l10n);
    if (pay.isHourly) {
      return Text(
        l10n.hrPresenceRecapPaidHourly,
        textAlign: TextAlign.end,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
      );
    }
    final absence = pay.absenceDeductionInCents ?? 0;
    if (absence == 0) return _none(l10n);
    final daily = pay.dailyRateInCents;
    return _amount(
      '− ${_money(absence, pay.currency)}',
      color: AppColors.presenceMarkAbsentInk,
      detail: daily == null
          ? null
          : l10n.hrPresenceRecapDeductionDays(
              row.unjustifiedAbsences,
              _money(daily, pay.currency),
            ),
    );
  }

  static Widget grossAfter(BuildContext context, HrAttendanceRecapRow row) {
    final pay = row.pay;
    if (pay == null) return _none(AppLocalizations.of(context)!);
    return _amount(
      _money(pay.grossAfterAbsenceInCents, pay.currency),
      strong: true,
    );
  }

  /// Les trois montants du pied, pour une devise.
  static List<Widget> totals(
    HrAttendanceRecapAmount amount, {
    required bool deduction,
    required Color ink,
  }) => [
    _amount(
      _money(amount.grossInCents, amount.currency),
      color: ink,
      strong: true,
    ),
    if (deduction)
      _amount(
        amount.absenceDeductionInCents == 0
            ? _money(0, amount.currency)
            : '− ${_money(amount.absenceDeductionInCents, amount.currency)}',
        color: ink,
        strong: true,
      ),
    _amount(
      _money(amount.grossAfterAbsenceInCents, amount.currency),
      color: ink,
      strong: true,
    ),
  ];

  static Widget _none(AppLocalizations l10n) => Text(
    l10n.hrPresenceNoValue,
    textAlign: TextAlign.end,
    style: EteeloColumnTableRow.figures(color: AppColors.textMutedAa),
  );

  static Widget _amount(
    String value, {
    String? detail,
    Color? color,
    bool strong = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        textAlign: TextAlign.end,
        style: EteeloColumnTableRow.figures(color: color, strong: strong),
      ),
      if (detail != null)
        Text(
          detail,
          textAlign: TextAlign.end,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
        ),
    ],
  );
}
