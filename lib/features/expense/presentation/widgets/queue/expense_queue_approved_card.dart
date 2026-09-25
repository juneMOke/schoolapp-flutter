import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_gesture_access.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_queue_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'école doit encore décaisser : les demandes accordées, dans
/// l'ordre où elles ont été décidées.
///
/// Elle vit **sous la file** et non dans un écran à part : la file est vide
/// quand tout est tranché, mais l'argent n'est pas sorti pour autant — et un
/// décideur qui vient de vider sa file doit voir ce qu'il a engagé.
class ExpenseQueueApprovedCard extends StatelessWidget {
  final ExpenseQueueView view;

  /// Au-delà, la carte renvoie au registre plutôt que de dérouler une
  /// seconde liste sous la première.
  static const int visibleRows = 6;

  final void Function(Expense expense, ExpenseGesture gesture) onGesture;
  final ValueChanged<Expense> onOpen;
  final VoidCallback onOpenRegister;

  const ExpenseQueueApprovedCard({
    super.key,
    required this.view,
    required this.onGesture,
    required this.onOpen,
    required this.onOpenRegister,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = view.approved;
    if (rows.isEmpty) return const SizedBox.shrink();
    final usd = view.approvedTotal.usdCents;
    final shown = rows.length <= visibleRows
        ? rows
        : rows.sublist(0, visibleRows);
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingM),
      child: ExpenseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: AppDimensions.detailMiniIconSize,
                  color: AppColors.bleuArdoise,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    l10n.expenseQueueApprovedTitle,
                    style: AppTextStyles.bodyStrong,
                  ),
                ),
                if (usd != null)
                  Text(
                    ExpenseMoneyText.usd(usd),
                    style: AppTextStyles.moneyTabular,
                  ),
              ],
            ),
            Text(
              l10n.expenseQueueApprovedSubtitle(rows.length),
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            for (final expense in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                child: _Row(
                  expense: expense,
                  onPay: () => onGesture(expense, ExpenseGesture.pay),
                  onOpen: () => onOpen(expense),
                ),
              ),
            if (rows.length > shown.length)
              Align(
                alignment: Alignment.centerLeft,
                child: EteeloButton.secondary(
                  label: l10n.expenseQueueSeeAllApproved(rows.length),
                  icon: Icons.receipt_long_outlined,
                  onPressed: onOpenRegister,
                  fullWidth: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Expense expense;
  final VoidCallback onPay;
  final VoidCallback onOpen;

  const _Row({
    required this.expense,
    required this.onPay,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final decidedAt = expense.decidedAt;
    final decider = expense.decidedByName;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS + AppDimensions.spacingXS,
        vertical: AppDimensions.expenseNotePaddingV,
      ),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoiseSoft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppDimensions.spacingM,
        runSpacing: AppDimensions.spacingS,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(expense.title, style: AppTextStyles.bodyStrong),
              Text(
                // Sans décideur connu, la ligne le DIT plutôt que d'inventer
                // un nom ou de laisser croire qu'il n'y en a pas eu.
                decidedAt == null || decider == null
                    ? l10n.expenseQueueApprovedUndated
                    : l10n.expenseQueueApprovedOn(
                        dates.formatShortMonthDay(decidedAt.toLocal()),
                        decider,
                      ),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimensions.spacingS,
            children: [
              Text(
                ExpenseMoneyText.of(expense),
                style: AppTextStyles.moneyTabular,
              ),
              PermissionGate.access(
                expenseGestureAccess(ExpenseGesture.pay),
                // Sans le droit de payer, la ligne reste consultable : on ne
                // ferme pas la lecture parce qu'on ferme l'écriture.
                fallback: EteeloButton.secondary(
                  label: l10n.expenseQueueOpenRequest,
                  icon: Icons.forum_outlined,
                  onPressed: onOpen,
                  fullWidth: false,
                ),
                child: EteeloButton.primary(
                  label: expenseGestureLabel(l10n, ExpenseGesture.pay),
                  icon: Icons.check_circle_outline,
                  onPressed: onPay,
                  fullWidth: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
