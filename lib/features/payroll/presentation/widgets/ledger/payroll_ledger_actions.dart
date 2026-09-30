import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_confirm_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_disbursement_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_pay_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_reason_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_stale_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les enchaînements du livre : ouvrir la modale d'un geste, puis le confier
/// au cubit. Les widgets n'y ont qu'un appel à faire.
class PayrollLedgerActions {
  final BuildContext context;

  const PayrollLedgerActions(this.context);

  PayrollCubit get _cubit => context.read<PayrollCubit>();

  PayrollState get _state => _cubit.state;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String nameOf(String staffMemberId) {
    final id = staffMemberId.toLowerCase();
    for (final member in _state.snapshot.members) {
      if (member.id.toLowerCase() == id) return member.fullName;
    }
    return staffMemberId;
  }

  Future<void> editVariables(PayrollLine line) async {
    final state = _state;
    final view = state.view;
    if (view == null) return;
    final month = view.month;
    final result = await PayrollVariablesDialog.show(
      context,
      PayrollVariablesDialog(
        name: nameOf(line.staffMemberId),
        line: line,
        settings: state.snapshot.settings,
        current:
            state.snapshot.variables[month]?[line.staffMemberId] ??
            PayrollVariables(staffMemberId: line.staffMemberId),
        preview: (variables) =>
            PayrollLedger.previewLine(state.snapshot, month, variables),
      ),
    );
    if (result == null || !context.mounted) return;
    await _cubit.perform(
      (commands) => commands.saveVariables(
        view,
        result,
        name: nameOf(line.staffMemberId),
      ),
    );
  }

  Future<void> submit() => _confirmThen(
    PayrollGestureKind.submit,
    title: _l10n.payrollSubmitTitle(_monthLabel),
    confirm: _l10n.payrollActionSubmit,
    warning: _l10n.payrollSubmitOffline,
  );

  Future<void> validate() => _confirmThen(
    PayrollGestureKind.validate,
    title: _l10n.payrollValidateTitle(_monthLabel),
    confirm: _l10n.payrollActionValidate,
    warning: _l10n.payrollValidateWarning,
  );

  Future<void> sendBack() => _reasonThen(
    PayrollGestureKind.returnToDraft,
    title: _l10n.payrollReturnTitle,
    confirm: _l10n.payrollActionReturn,
  );

  Future<void> reopen() => _reasonThen(
    PayrollGestureKind.reopen,
    title: _l10n.payrollReopenTitle(_monthLabel),
    confirm: _l10n.payrollActionReopen,
    hint: _l10n.payrollReopenHint,
  );

  String get _monthLabel => PayrollLabels.month(context, _state.month);

  Future<void> _confirmThen(
    PayrollGestureKind kind, {
    required String title,
    required String confirm,
    String? warning,
  }) async {
    final view = _state.view;
    if (view == null) return;
    final ok = await PayrollConfirmDialog.show(
      context,
      view: view,
      title: title,
      confirmLabel: confirm,
      warning: warning,
    );
    if (!ok || !context.mounted) return;
    await _cubit.perform((commands) => commands.gesture(view, kind));
  }

  Future<void> _reasonThen(
    PayrollGestureKind kind, {
    required String title,
    required String confirm,
    String? hint,
  }) async {
    final view = _state.view;
    if (view == null) return;
    final reason = await PayrollReasonDialog.show(
      context,
      title: title,
      confirmLabel: confirm,
      hint: hint,
    );
    if (reason == null || !context.mounted) return;
    await _cubit.perform(
      (commands) => commands.gesture(view, kind, reason: reason),
    );
  }

  /// La confrontation d'un refus `PAYROLL_STALE`.
  Future<void> compare(PayrollGesture gesture) async {
    final view = _state.view;
    final sync = await PayrollStaleDialog.show(
      context,
      gesture: gesture,
      current: view?.lines ?? const [],
      nameOf: nameOf,
    );
    if (sync && context.mounted) await _cubit.syncAndRefresh();
  }

  /// Verser, ou consulter le versement déjà fait.
  Future<void> openPayout(PayrollLine line, {required bool canWrite}) async {
    final view = _state.view;
    if (view == null) return;
    final existing = view.disbursements[line.staffMemberId];
    final name = nameOf(line.staffMemberId);
    if (existing != null) {
      final cancel = await PayrollDisbursementDialog.show(
        context,
        PayrollDisbursementDialog(
          name: name,
          disbursement: existing,
          canCancel: canWrite,
        ),
      );
      if (!cancel || !context.mounted) return;
      final reason = await PayrollReasonDialog.show(
        context,
        title: _l10n.payrollPayCancel,
        confirmLabel: _l10n.payrollPayCancel,
        destructive: true,
      );
      if (reason == null || !context.mounted) return;
      await _cubit.perform(
        (commands) => commands.cancelDisbursement(existing, reason),
      );
      return;
    }
    if (!canWrite) return;
    final draft = await PayrollPayDialog.show(
      context,
      PayrollPayDialog(
        name: name,
        view: view,
        line: line,
        profile:
            _state.snapshot.profiles[line.staffMemberId] ??
            StaffPayProfile.empty(line.staffMemberId),
      ),
    );
    if (draft == null || !context.mounted) return;
    await _cubit.perform(
      (commands) => commands.disburse(
        view,
        draft,
        name: name,
        amount: MoneyFormat.format(draft.amount),
      ),
    );
  }
}
