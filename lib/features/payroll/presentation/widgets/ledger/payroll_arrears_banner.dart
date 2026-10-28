import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_callout.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// À la préparation d'une paie (brouillon), ce que l'école doit encore sur
/// les mois validés antérieurs. Pas de report sur ce mois-ci (B4) : un
/// arriéré se paie sur son mois d'origine, depuis le registre.
class PayrollArrearsBanner extends StatelessWidget {
  final PayrollSnapshot snapshot;
  final PayrollMonthView view;

  const PayrollArrearsBanner({
    super.key,
    required this.snapshot,
    required this.view,
  });

  static List<PayrollArrearsAgent> _agents(
    PayrollSnapshot snapshot,
    PayrollMonthView view,
  ) => !view.isEditable
      ? const []
      : [
          for (final agent in PayrollArrears.of(
            snapshot,
            currentMonth: view.month,
          ))
            if (agent.oldestMonth.compareTo(view.month) < 0) agent,
        ];

  /// Le bandeau a-t-il quelque chose à dire ?
  static bool shows(PayrollSnapshot snapshot, PayrollMonthView view) =>
      _agents(snapshot, view).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final agents = _agents(snapshot, view);
    if (agents.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final due = PayrollLabels.perCurrency([
      for (final agent in agents)
        for (final arrear in agent.months)
          if (arrear.month.compareTo(view.month) < 0)
            (arrear.dueInCents, arrear.currency),
    ]).join(' · ');
    final months = {
      for (final agent in agents)
        for (final arrear in agent.months)
          if (arrear.month.compareTo(view.month) < 0) arrear.month,
    }.toList()..sort();
    return PayrollCallout(
      icon: Icons.warning_amber_rounded,
      kind: PayrollCalloutKind.tinted,
      tone: PayrollTone.submitted,
      title: l10n.payrollArrearsBanner(agents.length, due),
      details: [
        l10n.payrollArrearsBannerDetail(
          months.map((month) => PayrollLabels.month(context, month)).join(', '),
        ),
      ],
      action: EteeloButton.primary(
        label: l10n.payrollArrearsBannerAction,
        icon: Icons.account_balance_outlined,
        onPressed: () => context.go(
          AppRoutesNames.homeSubMenuPath(MenuConstants.hrPayrollArrearsId),
        ),
        fullWidth: false,
      ),
    );
  }
}
