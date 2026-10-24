import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!view.isEditable) return const SizedBox.shrink();
    final agents = [
      for (final agent in PayrollArrears.of(snapshot, currentMonth: view.month))
        if (agent.oldestMonth.compareTo(view.month) < 0) agent,
    ];
    if (agents.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final due = PayrollLabels.perCurrency([
      for (final agent in agents)
        for (final arrear in agent.months)
          if (arrear.month.compareTo(view.month) < 0)
            (arrear.dueInCents, arrear.currency),
    ]).join(' · ');
    final tone = PayrollTone.submitted;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: tone.color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.payrollArrearsBanner(agents.length, due),
                style: AppTypography.labelLarge.copyWith(color: tone.ink),
              ),
              EteeloButton.secondary(
                label: l10n.payrollArrearsBannerAction,
                icon: Icons.account_balance_outlined,
                onPressed: () => context.go(
                  AppRoutesNames.homeSubMenuPath(
                    MenuConstants.hrPayrollArrearsId,
                  ),
                ),
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
