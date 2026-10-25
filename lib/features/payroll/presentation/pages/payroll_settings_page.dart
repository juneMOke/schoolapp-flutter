import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/discard_changes_confirmation.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_draft.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_form.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_save_bar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Paie ▸ Configuration — le barème de l'école, à un seul endroit. La
/// direction le modifie (`hr.pay.manage`), l'économe le consulte. Il vaut
/// pour les paies encore à valider ; une paie validée garde le sien.
class PayrollSettingsPage extends StatelessWidget {
  const PayrollSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()..load(),
    child: const PayrollSettingsScreen(),
  );
}

class PayrollSettingsScreen extends StatelessWidget {
  const PayrollSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    width: PageContentWidth.wide,
    child: BlocConsumer<PayrollCubit, PayrollState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice != current.notice,
      listener: (context, state) => showPayrollNotice(
        context,
        state.notice!,
        monthLabel: PayrollLabels.month(context, state.month),
      ),
      buildWhen: (previous, current) =>
          previous.load != current.load ||
          previous.snapshot.settings != current.snapshot.settings,
      builder: (context, state) => switch (state.load) {
        PayrollLoad.failure => StaffResultsErrorState(
          failure: state.failure,
          onRetry: context.read<PayrollCubit>().load,
        ),
        PayrollLoad.loading => const EteeloListSkeleton(rowCount: 8),
        PayrollLoad.ready => _SettingsEditor(state: state),
      },
    ),
  );
}

class _SettingsEditor extends StatefulWidget {
  final PayrollState state;

  const _SettingsEditor({required this.state});

  @override
  State<_SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends State<_SettingsEditor> {
  late final PayrollSettingsDraft _draft = PayrollSettingsDraft(
    widget.state.snapshot.settings,
  );
  bool _saving = false;

  @override
  void didUpdateWidget(covariant _SettingsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _draft.rebase(widget.state.snapshot.settings);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  /// Les paies que le barème touche : brouillons et soumises, plus le mois
  /// en cours tant qu'il n'a pas d'en-tête (il se calcule déjà).
  int get _openPayrolls {
    final snapshot = widget.state.snapshot;
    final current = widget.state.today.substring(0, 7);
    return snapshot.headers.values
            .where((header) => header.status != PayrollStatus.validated)
            .length +
        (snapshot.headers.containsKey(current) ? 0 : 1);
  }

  Future<void> _save() async {
    final settings = _draft.settings;
    if (settings == null) return;
    setState(() => _saving = true);
    await context.read<PayrollCubit>().perform(
      (commands) => commands.saveSettings(settings),
    );
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = PermissionGate.allows(
      context,
      kPayrollManageAccess.requires,
    );
    return RouteExitGuard(
      isBusy: () => _saving,
      hasUnsavedWork: () => canManage && _draft.isDirty,
      confirmExit: () => confirmDiscardChanges(
        context,
        message: l10n.payrollSettingsDiscardMessage,
      ),
      child: ListenableBuilder(
        listenable: _draft,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.state.snapshot.hasEverSynced)
              EteeloNotice.warning(l10n.payrollSettingsNotYetSynced),
            if (!canManage) EteeloNotice.warning(l10n.payrollSettingsReadOnly),
            PayrollSettingsForm(draft: _draft, readOnly: !canManage),
            if (canManage) ...[
              PayrollSettingsSaveBar(
                dirty: _draft.isDirty,
                hasErrors: _draft.hasErrors,
                saving: _saving,
                openPayrolls: _openPayrolls,
                onReset: _draft.resetToDefaults,
                onSave: _save,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}
