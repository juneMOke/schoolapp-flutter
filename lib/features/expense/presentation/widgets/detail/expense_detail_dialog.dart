import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_dialog_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_actions.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_body.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_outcome.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_reason_dialog.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_composer.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_support.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_voucher_panel.dart';
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
  bool startRefusing = false,
  bool allowShortcuts = true,
  ExpenseDeclarationSupport? declaration,
}) => showEteeloAdaptiveDialog<ExpenseDetailOutcome>(
  context: context,
  builder: (_) => ExpenseDetailDialog(
    expense: expense,
    type: type,
    reader: reader,
    thread: thread,
    accountId: accountId,
    onComment: onComment,
    startRefusing: startRefusing,
    allowShortcuts: allowShortcuts,
    declaration: declaration,
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

  /// Ouvre la fiche avec la modale de motif déjà par-dessus : c'est le
  /// « Refuser » d'une ligne de file, qui amène le décideur devant ce qu'il
  /// refuse plutôt que de lui demander un mot dans le vide.
  final bool startRefusing;

  /// Les raccourcis d'écran (supprimer, dupliquer, modifier) ouvrent une
  /// saisie, et la saisie appartient au registre.
  final bool allowShortcuts;

  /// Pour une déclaration (v3) : la photo du bon et la règle d'annulation.
  final ExpenseDeclarationSupport? declaration;

  const ExpenseDetailDialog({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
    required this.thread,
    this.accountId,
    this.onComment,
    this.startRefusing = false,
    this.allowShortcuts = true,
    this.declaration,
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

  ExpenseVoucherLoad _voucher = const ExpenseVoucherLoading();

  /// Prudent tant que la règle n'a pas répondu : « Annuler » caché.
  bool _cancelAllowed = false;
  bool _cancelResolved = false;

  /// La photo est arrivée mais ne se décode pas : on ne vise pas ce qu'on
  /// n'a pas vu.
  bool _voucherBroken = false;

  @override
  void initState() {
    super.initState();
    if (_expense.isDeclaration && widget.declaration != null) {
      _loadVoucher();
      _resolveCancel();
    }
    // Après le premier cadre : la fiche doit être posée pour rester derrière.
    if (widget.startRefusing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refuse();
      });
    }
  }

  Future<void> _loadVoucher() async {
    setState(() => _voucher = const ExpenseVoucherLoading());
    final result = await widget.declaration!.loadVoucher(_expense);
    if (!mounted) return;
    setState(
      () => _voucher = result.fold(
        ExpenseVoucherFailed.new,
        ExpenseVoucherLoaded.new,
      ),
    );
  }

  Future<void> _resolveCancel() async {
    final allowed = await widget.declaration!.canCancel(_expense);
    if (!mounted) return;
    setState(() {
      _cancelAllowed = allowed;
      _cancelResolved = true;
    });
  }

  /// La photo s'est montrée : elle est sur ce poste, « Viser » s'ouvre.
  bool get _voucherSeen => switch (_voucher) {
    ExpenseVoucherLoaded(:final image) => image != null && !_voucherBroken,
    _ => false,
  };

  void _onVoucherBroken() {
    if (_voucherBroken) return;
    // Signalé pendant la construction de l'image : on attend la fin du cadre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _voucherBroken = true);
    });
  }

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

  /// Les motifs se demandent dans une modale par-dessus la fiche : sous la
  /// photo du bon ou le fil, un panneau ouvert en bas restait hors de vue.
  Future<void> _refuse() async {
    final reason = await showExpenseRefusalDialog(context, expense: _expense);
    if (!mounted || reason == null) return;
    _close(ExpenseDetailGesture(ExpenseGesture.refuse, note: reason));
  }

  Future<void> _flag() async {
    final reason = await showExpenseFlagDialog(context, expense: _expense);
    if (!mounted || reason == null) return;
    _close(ExpenseDetailGesture(ExpenseGesture.flag, note: reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = _expense.number;
    // Grand écran : la fiche s'élargit et porte le fil en colonne (cf.
    // `ExpenseDetailBody`). Ailleurs elle garde sa largeur de lecture, le fil
    // en pied — une modale élargie sur une seule colonne n'apporterait que des
    // lignes plus longues. Passé à `Dialog` lui-même : la M3 le plafonne
    // sinon à 560, quoi qu'on mette dessous.
    final maxWidth =
        MediaQuery.sizeOf(context).width >=
            AppDimensions.expenseDetailDialogWideMaxWidth +
                2 * AppDimensions.spacingL
        ? AppDimensions.expenseDetailDialogWideMaxWidth
        : AppDimensions.expenseDetailDialogMaxWidth;
    return EteeloAdaptiveDialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      maxWidth: maxWidth,
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
                declarationSection: widget.declaration == null
                    ? null
                    : ExpenseVoucherPanel(
                        expense: _expense,
                        load: _voucher,
                        onRetry: _loadVoucher,
                        onImageError: _onVoucherBroken,
                        cancelBlocked:
                            _expense.status == ExpenseStatus.paid &&
                            _cancelResolved &&
                            !_cancelAllowed,
                      ),
              ),
            ],
          ),
        ),
        footer: [
          ExpenseDetailActions(
            expense: _expense,
            isStaffAdvance:
                _expense.staffAdvance != null ||
                widget.type?.code == ExpenseStaffAdvance.typeCode,
            accountId: widget.accountId,
            onShortcut: (choice) => _close(ExpenseDetailShortcut(choice)),
            onGesture: (gesture) => _close(ExpenseDetailGesture(gesture)),
            onRefuse: _refuse,
            onFlag: _flag,
            voucherSeen: _voucherSeen,
            // Une déclaration sans la règle de clôture ne s'annule pas d'ici :
            // le geste partirait sans savoir si la journée est figée.
            cancelAllowed: !_expense.isDeclaration || _cancelAllowed,
            canRedeclare: widget.declaration?.canRedeclare ?? false,
            allowShortcuts: widget.allowShortcuts,
          ),
        ],
      ),
    );
  }
}
