import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler_registry.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_enrollment_duplicates_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_guard.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepperScope extends StatefulWidget {
  final EnrollmentDetail enrollmentDetail;
  final EnrollmentDetailIntent detailIntent;
  final EnrollmentDetailPolicy detailPolicy;
  final ValueChanged<int>? onStepChanged;

  /// Relayé au stepper : voir [EnrollmentStepper.correctionOffered].
  final bool correctionOffered;

  const EnrollmentStepperScope({
    super.key,
    required this.enrollmentDetail,
    required this.detailIntent,
    required this.detailPolicy,
    this.onStepChanged,
    this.correctionOffered = false,
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

  /// Sonde de doublon de l'étape Identité. Créée **ici** parce que sa mémoire
  /// est celle d'une session de saisie : ce que le guichet vient d'assumer ne
  /// doit pas lui être redemandé au prochain aller-retour d'étape, et doit
  /// l'être à nouveau au dossier suivant.
  late final EnrollmentDuplicateGuard _duplicateGuard;

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
    // `.lazy` et non la sonde en main : ce wizard se monte en consultation, en
    // réédition, en réinscription — des parcours qui ne l'interrogeront jamais.
    // Le conteneur n'est touché qu'au moment où la question se pose vraiment.
    _duplicateGuard = EnrollmentDuplicateGuard.lazy(
      () => getIt<ProbeEnrollmentDuplicatesUseCase>(),
    );

    final handlerDependencies = EnrollmentStepHandlerDependencies(
      personalInfoController: _personalInfoController,
      addressController: _addressController,
      academicInfoController: _academicInfoController,
      academicTargetInfoController: _academicTargetInfoController,
      studentChargesController: _studentChargesController,
      guardianInfoController: _guardianInfoController,
      duplicateGuard: _duplicateGuard,
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

  // Réaction offline-first commune à TOUS les parcours (NEW vierge, RE/PRE/
  // reprise seedés) : toute erreur d'écriture locale d'une étape OU d'un seed
  // remonte ici en une seule source de toast (les étapes ne font que
  // déverrouiller leur bouton). La finalisation (dernière étape) a sa PROPRE
  // sur-couche de résultat (`EnrollmentFinalizeOverlay`, popin succès/échec +
  // navigation) — son erreur dédiée `EnrollmentDraftFinalizeError` ne
  // transite donc pas par ce toast générique.
  void _onDraftConfirmState(
    BuildContext context,
    EnrollmentOfflineState state,
  ) {
    if (state is EnrollmentDraftError) {
      final l10n = AppLocalizations.of(context)!;
      AppSnackBar.showError(context, l10n.offlineWriteError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EnrollmentStepperFlowBloc>.value(
      value: _flowBloc,
      child: BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
        listenWhen: (previous, current) =>
            previous != current && current is EnrollmentDraftError,
        listener: _onDraftConfirmState,
        child: EnrollmentStepper(
          enrollmentDetail: widget.enrollmentDetail,
          detailIntent: widget.detailIntent,
          detailPolicy: widget.detailPolicy,
          stepHandlers: _stepHandlers,
          onStepChanged: widget.onStepChanged,
          correctionOffered: widget.correctionOffered,
        ),
      ),
    );
  }
}
