import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_advance_status_pill.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_repayment_bar.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_tone_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les avances et prêts de l'agent, tous statuts : ce qui est rendu, ce qui
/// reste, la prochaine retenue ; puis les demandes encore dans le circuit de
/// dépense. Lecture seule — la demande se fait dans Avances & prêts.
class PayrollAgentLoansCard extends StatelessWidget {
  final PayrollAgentSituation situation;
  final PayrollSnapshot snapshot;

  /// Le livre où se lit le statut de chaque avance (le mois affiché).
  final PayrollMonthView view;

  const PayrollAgentLoansCard({
    super.key,
    required this.situation,
    required this.snapshot,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final empty = situation.advances.isEmpty && situation.requests.isEmpty;
    return EteeloPanelCard(
      title: l10n.payrollAgentLoansTitle,
      child: empty
          ? Text(
              l10n.payrollAgentLoansEmpty,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final request in situation.requests)
                  _RequestRow(request: request),
                for (final advance in situation.advances)
                  _AdvanceRow(
                    advance: advance,
                    situation: situation,
                    snapshot: snapshot,
                    view: view,
                  ),
              ],
            ),
    );
  }
}

String _kind(AppLocalizations l10n, int installments) => installments > 1
    ? l10n.payrollAgentAdvanceLoan(installments)
    : l10n.payrollAgentAdvanceSingle;

class _AdvanceRow extends StatelessWidget {
  final SalaryAdvance advance;
  final PayrollAgentSituation situation;
  final PayrollSnapshot snapshot;
  final PayrollMonthView view;

  const _AdvanceRow({
    required this.advance,
    required this.situation,
    required this.snapshot,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = advance.amount.currency;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final amount = advance.amount.amountInCents;
    final deducted = amount - advance.remainingInCents;
    final next = advance.isOngoing
        ? situation.nextInstallment(advance.id)
        : null;
    final upcoming = situation.upcoming;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textMutedAa,
    );
    return _Entry(
      title: _kind(l10n, advance.installments),
      detail:
          '${PayrollLabels.reason(l10n, advance.reason)} · '
          '${PayrollLabels.day(context, advance.grantedOn)}',
      amount: money(amount),
      pill: PayrollAdvanceStatusPill(
        status: PayrollAdvanceRules.statusOf(advance, view, snapshot),
        advance: advance,
      ),
      children: [
        if (advance.isLive)
          PayrollRepaymentBar(
            ratio: amount == 0 ? 0 : deducted / amount,
            deducted: l10n.payrollAdvanceDeducted(money(deducted)),
            remaining: l10n.payrollAdvanceRemaining(
              money(advance.remainingInCents),
            ),
          ),
        // Ce que le mois retiendra vraiment : le brut peut ne pas couvrir
        // l'échéance, le reste glisse au mois suivant.
        if (next != null && upcoming != null)
          Text(
            next.carriedInCents > 0
                ? l10n.payrollAgentNextInstallmentCarried(
                    money(next.takenInCents),
                    PayrollLabels.month(context, upcoming.month),
                    money(next.carriedInCents),
                  )
                : l10n.payrollAgentNextInstallment(
                    money(next.takenInCents),
                    PayrollLabels.month(context, upcoming.month),
                  ),
            style: muted,
          ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  final PayrollAdvanceRequest request;

  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = switch (request.status) {
      ExpenseStatus.pending => (
        l10n.payrollAdvanceCircuitToApprove,
        PayrollTone.submitted,
      ),
      ExpenseStatus.approved => (
        l10n.payrollAdvanceCircuitToPay,
        PayrollTone.validated,
      ),
      _ => (l10n.payrollAdvanceStatusRefused, PayrollTone.alert),
    };
    return _Entry(
      title: _kind(l10n, request.block.installments),
      detail: l10n.payrollAdvanceCircuitVia,
      amount: PayrollLabels.money(
        request.amount.amountInCents,
        request.amount.currency,
      ),
      pill: PayrollTonePill(label: label, tone: tone),
      children: const [],
    );
  }
}

/// Intitulé et montant, détail et statut, puis ce que la ligne ajoute.
class _Entry extends StatelessWidget {
  final String title;
  final String detail;
  final String amount;
  final Widget pill;
  final List<Widget> children;

  const _Entry({
    required this.title,
    required this.detail,
    required this.amount,
    required this.pill,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                pill,
              ],
            ),
          ],
        ),
        for (final child in children) ...[
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ],
    ),
  );
}
