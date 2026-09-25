import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_chain.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_banner.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_reference_row.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_rejection.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_situation_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_composer.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps de la fiche (spec §8) : le montant en tête, à l'échelle du titre
/// — c'est le fait que l'on vient vérifier —, la chaîne de validation et ce
/// que la demande attend, puis un tableau de références, et le fil en pied.
class ExpenseDetailBody extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;

  /// Le fil, lu avant l'ouverture de la fiche ; `null` s'il n'a pas pu l'être.
  final List<ExpenseMessage>? thread;

  /// Le compte de la session, pour reconnaître ses propres messages.
  final String? accountId;

  /// Envoie un commentaire ; `null` laisse le fil en lecture seule.
  final Future<ExpenseCommentResult> Function(String body)? onSend;

  const ExpenseDetailBody({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
    required this.thread,
    this.accountId,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final paidOn = expense.paidOn;
    final rows = <(String, String)>[
      (l10n.expenseDetailType, type?.label ?? l10n.expenseTypeUnknown),
      (l10n.expenseDetailSupplier, expense.supplier ?? l10n.expenseNoSupplier),
      (
        l10n.expenseDetailFunding,
        expenseFundingLabel(l10n, expense.fundingSource),
      ),
      (
        l10n.expenseDetailRecordedBy,
        expense.recordedByName ?? l10n.expenseNoValue,
      ),
      (l10n.expenseDetailDate, dates.formatFullDate(expense.expenseDate)),
      // A2 — « Payée le … » : la date qui comptera le jour où la source de
      // fonds débitera la caisse.
      if (expense.isPaid)
        (
          l10n.expenseDetailPaidOn,
          paidOn == null ? l10n.expenseNoValue : dates.formatFullDate(paidOn),
        ),
      (
        l10n.expenseDetailNumber,
        expense.number ?? l10n.expenseDetailNumberPending,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpenseDetailBanner(expense: expense, type: type, reader: reader),
        if (expense.isRejected) ...[
          const SizedBox(
            height: AppDimensions.spacingS + AppDimensions.spacingXS,
          ),
          ExpenseDetailRejection(code: expense.syncErrorCode),
        ],
        const SizedBox(height: AppDimensions.spacingM),
        // La chaîne d'abord, l'encart ensuite : où en est la demande, puis ce
        // qu'elle attend. L'inverse ferait lire la conséquence avant l'état.
        ExpenseChain(expense: expense),
        ExpenseSituationNote(expense: expense),
        const SizedBox(height: AppDimensions.spacingM),
        expense.description == null
            ? Text(
                l10n.expenseDetailNoDescription,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Text(
                expense.description!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
        const SizedBox(
          height: AppDimensions.spacingS + AppDimensions.spacingXS,
        ),
        for (var i = 0; i < rows.length; i++)
          ExpenseDetailReferenceRow(
            label: rows[i].$1,
            value: rows[i].$2,
            last: i == rows.length - 1,
          ),
        Container(
          margin: const EdgeInsets.only(top: AppDimensions.spacingL),
          padding: const EdgeInsets.only(top: AppDimensions.spacingM),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ExpenseThreadPanel(
            messages: thread,
            accountId: accountId,
            onSend: onSend,
          ),
        ),
      ],
    );
  }
}
