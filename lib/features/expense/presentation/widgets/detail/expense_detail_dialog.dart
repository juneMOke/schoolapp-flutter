import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_dialog_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_actions.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_body.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_outcome.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_refusal_panel.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_composer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

export 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_outcome.dart';

/// Ouvre la fiche d'une demande. Tout geste offert ferme la fiche et rend ce
/// qu'il demande — raccourci d'écran ou geste du circuit.
///
/// Le fil est **déjà lu** quand la fiche s'ouvre : `null` dit qu'il n'a pas pu
/// l'être, et une liste vide qu'il n'y a rien à lire. La fiche ne charge donc
/// rien elle-même — une lecture locale n'a pas besoin d'un écran d'attente.
Future<ExpenseDetailOutcome?> showExpenseDetailDialog(
  BuildContext context, {
  required Expense expense,
  required ExpenseType? type,
  required ExpenseUsdReader reader,
  required List<ExpenseMessage>? thread,
  String? accountId,
  Future<ExpenseCommentResult> Function(String body)? onComment,
}) => showDialog<ExpenseDetailOutcome>(
  context: context,
  builder: (_) => ExpenseDetailDialog(
    expense: expense,
    type: type,
    reader: reader,
    thread: thread,
    accountId: accountId,
    onComment: onComment,
  ),
);

class ExpenseDetailDialog extends StatefulWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;
  final List<ExpenseMessage>? thread;
  final String? accountId;

  /// Écrit le commentaire et rend le fil relu. `null` : fil en lecture seule.
  final Future<ExpenseCommentResult> Function(String body)? onComment;

  const ExpenseDetailDialog({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
    required this.thread,
    this.accountId,
    this.onComment,
  });

  @override
  State<ExpenseDetailDialog> createState() => _ExpenseDetailDialogState();
}

class _ExpenseDetailDialogState extends State<ExpenseDetailDialog> {
  late final Expense _expense = widget.expense;

  /// Le fil **vit** dans la fiche : commenter est le seul geste qui ne la
  /// ferme pas, parce qu'on commente en lisant. Les autres transitionnent, et
  /// la fiche rouvre sur un registre relu.
  late List<ExpenseMessage>? _thread = widget.thread;

  /// Le panneau de motif est ouvert : le refus attend son mot.
  bool _refusing = false;

  Future<ExpenseCommentResult> _send(String body) async {
    final result = await widget.onComment!(body);
    if (!mounted) return result;
    final thread = result.thread;
    // Une relecture manquée ne défait pas le fil affiché : le message est
    // écrit, il apparaîtra à la prochaine ouverture.
    if (thread != null) setState(() => _thread = thread);
    return result;
  }

  void _close([ExpenseDetailOutcome? outcome]) =>
      Navigator.of(context).pop(outcome);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = _expense.number;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.expenseDetailDialogMaxWidth,
        ),
        child: EteeloDialogBody(
          header: ExpenseDialogHeader(
            eyebrow: number == null
                ? l10n.expenseDetailEyebrowPending
                : l10n.expenseDetailEyebrow(number),
            title: _expense.title,
            subtitle: l10n.expenseJoin(
              widget.type?.label ?? l10n.expenseTypeUnknown,
              MaterialLocalizations.of(
                context,
              ).formatFullDate(_expense.expenseDate),
            ),
            onClose: _close,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpenseDetailBody(
                  expense: _expense,
                  type: widget.type,
                  reader: widget.reader,
                  thread: _thread,
                  accountId: widget.accountId,
                  onSend: widget.onComment == null ? null : _send,
                ),
                // Le panneau s'ouvre DANS la fiche, sous le fil : le décideur
                // garde sous les yeux le montant, la chaîne et l'historique —
                // c'est ce qu'il refuse.
                if (_refusing)
                  ExpenseRefusalPanel(
                    onCancel: () => setState(() => _refusing = false),
                    onConfirm: (reason) => _close(
                      ExpenseDetailGesture(ExpenseGesture.refuse, note: reason),
                    ),
                  ),
              ],
            ),
          ),
          footer: [
            ExpenseDetailActions(
              expense: _expense,
              accountId: widget.accountId,
              onShortcut: (choice) => _close(ExpenseDetailShortcut(choice)),
              onGesture: (gesture) => _close(ExpenseDetailGesture(gesture)),
              onRefuse: () => setState(() => _refusing = true),
            ),
          ],
        ),
      ),
    );
  }
}
