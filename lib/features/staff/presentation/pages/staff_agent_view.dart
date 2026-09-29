import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_breadcrumb.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_progression.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_agent_body.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_agent_footer.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_agent_header.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps de la page agent : en-tête, fil d'étapes, étape courante et pied.
/// Lit les cubits que [StaffAgentPage] fournit.
class StaffAgentView extends StatefulWidget {
  final StaffContractKind? kind;
  final String today;

  const StaffAgentView({super.key, required this.kind, required this.today});

  @override
  State<StaffAgentView> createState() => _StaffAgentViewState();
}

class _StaffAgentViewState extends State<StaffAgentView> {
  AddressGeoCatalog? _catalog;

  /// L'état d'avant la transition écoutée : c'est lui qui dit si
  /// l'enregistrement était une création.
  StaffAgentState? _before;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await AddressGeoCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = catalog);
    } catch (_) {
      // Référentiel illisible : les listes restent vides, la saisie en cours
      // n'est pas perdue.
    }
  }

  Future<void> _leave(StaffAgentCubit cubit) async {
    final state = cubit.state;
    if (state.mode == StaffAgentMode.edit && cubit.hasChanges) {
      final l10n = AppLocalizations.of(context)!;
      final discard = await showAppConfirmationDialog(
        context: context,
        title: l10n.staffDiscardTitle,
        message: l10n.staffDiscardMessage,
        confirmLabel: l10n.staffDiscardConfirm,
        cancelLabel: l10n.staffDiscardKeep,
        isDestructive: true,
      );
      if (!mounted || !discard) return;
      cubit.cancelEdit();
      return;
    }
    if (state.mode == StaffAgentMode.edit) {
      cubit.cancelEdit();
      return;
    }
    Navigator.of(context).pop();
  }

  void _onStateChanged(
    BuildContext context,
    StaffAgentState previous,
    StaffAgentState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state.justSaved) {
      AppSnackBar.showSuccess(
        context,
        previous.mode == StaffAgentMode.create
            ? l10n.staffSavedCreated(state.member?.fullName ?? '')
            : l10n.staffSavedUpdated,
      );
    }
    if (state.failure != null && previous.failure == null) {
      AppSnackBar.showError(context, l10n.staffSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StaffAgentCubit>();
    return BlocConsumer<StaffAgentCubit, StaffAgentState>(
      listenWhen: (previous, current) {
        _before = previous;
        return current.justSaved ||
            (current.failure != null && previous.failure == null);
      },
      listener: (context, state) =>
          _onStateChanged(context, _before ?? state, state),
      builder: (context, state) {
        final canWrite = PermissionGate.allows(context, const [
          Perm.hrStaffWrite,
        ]);
        return PopScope(
          canPop: state.mode != StaffAgentMode.edit,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_leave(cubit));
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: Column(
              children: [
                StaffAgentHeader(
                  state: state,
                  kind: widget.kind,
                  onBack: () => unawaited(_leave(cubit)),
                  onEdit: state.mode == StaffAgentMode.view && canWrite
                      ? cubit.startEdit
                      : null,
                ),
                WizardBreadcrumb(
                  titles: [
                    l10n.staffStepIdentity,
                    l10n.staffStepAddress,
                    l10n.staffStepJob,
                    l10n.staffStepDocuments,
                  ],
                  currentStep: state.step,
                  progress: (state.step + 1) / StaffAgentState.stepCount,
                  progression: WizardStepProgression(
                    stepCount: StaffAgentState.stepCount,
                    currentStep: state.step,
                    maxStep: state.reached,
                  ),
                  errorSteps: state.visibleErrorSteps,
                  onStepTap: cubit.goTo,
                ),
                Expanded(
                  child: StaffAgentBody(
                    state: state,
                    catalog: _catalog,
                    today: widget.today,
                    onChanged: cubit.updateDraft,
                    jobAppendix: switch (state.member) {
                      final member? when state.mode == StaffAgentMode.view =>
                        StaffContractPanel(member: member, today: widget.today),
                      _ => null,
                    },
                  ),
                ),
                StaffAgentFooter(
                  state: state,
                  onPrevious: cubit.previous,
                  onNext: cubit.next,
                  onSave: () => unawaited(cubit.save()),
                  onCancel: () => unawaited(_leave(cubit)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
