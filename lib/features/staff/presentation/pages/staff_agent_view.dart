import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_breadcrumb.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_progression.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_agent_body.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_agent_footer.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_agent_header.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_panel.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_initial_contract_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/documents/staff_dossier_panel.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_discard_confirmation.dart';
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

  /// Une modification en cours serait perdue : la fiche se ferme ou le
  /// navigateur la quitte sur ce seul critère.
  bool _hasUnsavedWork(StaffAgentCubit cubit) =>
      cubit.state.mode == StaffAgentMode.edit && cubit.hasChanges;

  Future<bool> _confirmDiscard() => confirmStaffDiscard(context);

  Future<void> _leave(StaffAgentCubit cubit) async {
    final state = cubit.state;
    if (_hasUnsavedWork(cubit)) {
      final discard = await _confirmDiscard();
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
    // Une création enregistrée devient un agent : ses contrats et ses pièces
    // se lisent désormais, que la page n'a pas pu charger à l'ouverture.
    final created = state.member;
    if (state.justSaved && previous.member == null && created != null) {
      unawaited(context.read<StaffDossierCubit>().load(created.id));
      unawaited(_afterCreation(context, created.id, previous.contractToPose));
    }
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

  /// La fiche est écrite : son contrat initial se pose à sa suite — en file
  /// derrière elle, il attend son envoi. La fiche s'ouvre alors sur
  /// « Poste & contrat », où le geste dit s'il a réussi.
  Future<void> _afterCreation(
    BuildContext context,
    String memberId,
    StaffContractDraft? contract,
  ) async {
    final contracts = context.read<StaffContractsCubit>();
    final agent = context.read<StaffAgentCubit>();
    if (contract == null) {
      await contracts.load(memberId);
      return;
    }
    agent.goTo(StaffAgentState.jobStep);
    // Le bloc des contrats doit être monté pour annoncer l'issue du geste.
    await WidgetsBinding.instance.endOfFrame;
    if (await contracts.add(memberId, contract)) await agent.refreshMember();
  }

  /// Ce qui suit une étape hors saisie : les contrats sous « Poste », les
  /// pièces sous « Diplômes ».
  Map<int, Widget> _appendices(StaffAgentState state, StaffAgentCubit cubit) =>
      switch ((state.mode, state.member)) {
        (StaffAgentMode.create, _) => {
          StaffAgentState.jobStep: StaffInitialContractCard(
            contract: state.initialContract,
            errors: state.visibleContractErrors,
            onChanged: cubit.updateInitialContract,
            onClear: cubit.clearInitialContract,
          ),
        },
        (StaffAgentMode.view, final member?) => {
          StaffAgentState.jobStep: StaffContractPanel(
            member: member,
            today: widget.today,
          ),
          StaffAgentState.jobStep + 1: StaffDossierPanel(
            member: member,
            today: widget.today,
          ),
        },
        (StaffAgentMode.edit, final member?) => {
          StaffAgentState.jobStep: StaffContractPanel(
            member: member,
            today: widget.today,
            readOnly: true,
          ),
        },
        _ => const {},
      };

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
        // Consultation sur grand écran : la fiche entière d'un coup d'œil.
        // La modification reprend l'assistant, étape par étape.
        final wholeFile =
            state.mode == StaffAgentMode.view &&
            MediaQuery.sizeOf(context).width >= AppBreakpoints.staffFileViewMin;
        // Précédent du navigateur : la page est poussée au-dessus du fichier
        // du personnel, dont la route consulte cette garde (`onExit`) — ou,
        // sous RH · Personnel, elle a sa propre route (`HrAgentRoutes`).
        return RouteExitGuard(
          hasUnsavedWork: () => _hasUnsavedWork(cubit),
          confirmExit: _confirmDiscard,
          child: PopScope(
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
                  if (!wholeFile)
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
                      wholeFile: wholeFile,
                      state: state,
                      catalog: _catalog,
                      today: widget.today,
                      onChanged: cubit.updateDraft,
                      appendices: _appendices(state, cubit),
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
          ),
        );
      },
    );
  }
}
