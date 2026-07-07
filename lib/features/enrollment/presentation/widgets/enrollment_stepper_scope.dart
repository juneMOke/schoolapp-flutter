import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler_registry.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_navigation_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepperScope extends StatefulWidget {
  final EnrollmentDetail enrollmentDetail;
  final EnrollmentDetailIntent detailIntent;
  final EnrollmentDetailPolicy detailPolicy;
  final ValueChanged<int>? onStepChanged;

  const EnrollmentStepperScope({
    super.key,
    required this.enrollmentDetail,
    required this.detailIntent,
    required this.detailPolicy,
    this.onStepChanged,
  });

  @override
  State<EnrollmentStepperScope> createState() => _EnrollmentStepperScopeState();
}

class _EnrollmentStepperScopeState extends State<EnrollmentStepperScope> {
  late final EnrollmentStepperFlowBloc _flowBloc;
  late final List<EnrollmentStepHandler> _stepHandlers;
  late final EnrollmentStepSubmitController _personalInfoController;
  late final EnrollmentStepSubmitController _addressController;
  late final EnrollmentStepSubmitController _academicInfoController;
  late final EnrollmentStepSubmitController _academicTargetInfoController;
  late final EnrollmentStepSubmitController _studentChargesController;
  late final EnrollmentStepSubmitController _guardianInfoController;

  // Confirmation offline confirmée (pending-sync) déjà traitée : évite un double
  // retour visuel / une double navigation si l'état est ré-émis.
  bool _handledPendingSync = false;

  EnrollmentStepFlowPlan _buildFlowPlan(EnrollmentDetail detail) {
    return EnrollmentStepHandlerRegistry.buildPlanFromHandlers(
      handlers: _stepHandlers,
      detail: detail,
    );
  }

  @override
  void initState() {
    super.initState();
    _personalInfoController = EnrollmentStepSubmitController();
    _addressController = EnrollmentStepSubmitController();
    _academicInfoController = EnrollmentStepSubmitController();
    _academicTargetInfoController = EnrollmentStepSubmitController();
    _studentChargesController = EnrollmentStepSubmitController();
    _guardianInfoController = EnrollmentStepSubmitController();

    final handlerDependencies = EnrollmentStepHandlerDependencies(
      personalInfoController: _personalInfoController,
      addressController: _addressController,
      academicInfoController: _academicInfoController,
      academicTargetInfoController: _academicTargetInfoController,
      studentChargesController: _studentChargesController,
      guardianInfoController: _guardianInfoController,
    );
    _stepHandlers = EnrollmentStepHandlerRegistry.create(handlerDependencies);

    final flowPlan = _buildFlowPlan(widget.enrollmentDetail);

    _flowBloc = EnrollmentStepperFlowBloc(
      totalSteps: flowPlan.totalSteps,
      initialStepStates: flowPlan.initialStepStates,
    );
  }

  @override
  void didUpdateWidget(covariant EnrollmentStepperScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrollmentDetail != widget.enrollmentDetail) {
      final flowPlan = _buildFlowPlan(widget.enrollmentDetail);
      _flowBloc.add(EnrollmentStepperStatesSynced(flowPlan.initialStepStates));
    }
  }

  @override
  void dispose() {
    _flowBloc.close();
    super.dispose();
  }

  // Réaction offline-first à la confirmation local-first (miroir du listener
  // online historique porté par EnrollmentStepper) :
  //  - pending-sync → pastille globale + toast « en attente de synchro » +
  //    navigation de succès identique au flux online ;
  //  - erreur → toast d'échec d'écriture locale.
  void _onOfflineConfirmState(
    BuildContext context,
    EnrollmentOfflineState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state is EnrollmentOfflineConfirmedPendingSync) {
      if (_handledPendingSync) return;
      _handledPendingSync = true;
      context.read<SyncStatusCubit>().notifyLocalWrite();
      AppSnackBar.showInfo(context, l10n.offlineEnrollmentQueued);
      EnrollmentNavigationHelper.redirectToFirstRegistrationFromHome(context);
    } else if (state is EnrollmentOfflineError) {
      AppSnackBar.showError(context, l10n.offlineWriteError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EnrollmentStepperFlowBloc>.value(
      value: _flowBloc,
      child: BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
        listenWhen: (previous, current) =>
            previous != current &&
            (current is EnrollmentOfflineConfirmedPendingSync ||
                current is EnrollmentOfflineError),
        listener: _onOfflineConfirmState,
        child: EnrollmentStepper(
          enrollmentDetail: widget.enrollmentDetail,
          detailIntent: widget.detailIntent,
          detailPolicy: widget.detailPolicy,
          stepHandlers: _stepHandlers,
          onStepChanged: widget.onStepChanged,
        ),
      ),
    );
  }
}
