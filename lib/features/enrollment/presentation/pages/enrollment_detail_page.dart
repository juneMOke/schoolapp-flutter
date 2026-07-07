import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_detail_mapper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_app_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_scope.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentDetailPage extends StatefulWidget {
  final EnrollmentDetailIntent intent;

  const EnrollmentDetailPage({super.key, required this.intent});

  @override
  State<EnrollmentDetailPage> createState() => _EnrollmentDetailPageState();
}

class _EnrollmentDetailPageState extends State<EnrollmentDetailPage> {
  late EnrollmentDetailPolicy _policy;
  late EnrollmentDetailIntent _effectiveIntent;
  int _currentStep = 0;

  // Parcours NEW offline-first : ids client figés + dernier détail lu en base
  // locale, conservés à travers les états transitoires du brouillon.
  DraftIds? _draftIds;
  LocalEnrollmentDetail? _draftLocal;

  // Mémoïsation de l'agrégat NEW : EnrollmentDetail n'est pas Equatable, donc
  // recréer une instance à chaque build resynchroniserait le stepper (perte de
  // l'étape/dirty). On ne recompose que si une entrée (identité) a changé.
  EnrollmentDetail? _cachedAggregate;
  LocalEnrollmentDetail? _cachedLocal;
  DraftIds? _cachedIds;
  Bootstrap? _cachedBootstrap;

  bool get _isNewOffline =>
      _effectiveIntent.origin == EnrollmentDetailOrigin.newFirstRegistration;

  @override
  void initState() {
    super.initState();
    _policy = EnrollmentDetailPolicyResolver.fromIntent(widget.intent);
    _effectiveIntent = widget.intent;
    _requestBootstrapContexts();
    _initializeJourney();
  }

  @override
  void didUpdateWidget(covariant EnrollmentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent != widget.intent) {
      final shouldRefreshFromRouter = widget.intent != _effectiveIntent;
      _policy = EnrollmentDetailPolicyResolver.fromIntent(widget.intent);
      _effectiveIntent = widget.intent;
      _currentStep = 0;
      if (shouldRefreshFromRouter) {
        _requestBootstrapContexts();
        _initializeJourney();
      }
    }
  }

  /// Amorce du parcours : brouillon local (NEW) ou chargement serveur (autres).
  void _initializeJourney() {
    if (_isNewOffline) {
      context.read<EnrollmentDraftBloc>().add(const StartDraftRequested());
      return;
    }
    _requestDetail();
  }

  void _requestDetail() {
    _policy.requestLoad(context.read<EnrollmentBloc>(), _effectiveIntent);
  }

  void _requestBootstrapContexts() {
    if (_policy.requiresCurrentYearBootstrap(_effectiveIntent)) {
      context.read<BootstrapCurrentYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPayloadKey,
        ),
      );
    }

    if (_policy.requiresPreviousYearBootstrap(_effectiveIntent)) {
      context.read<BootstrapPreviousYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPreviousYearPayloadKey,
        ),
      );
    }
  }

  /// Handle side effects after a successful enrollment creation:
  /// resolve next intent, refresh detail/summaries, sync route, then consume result.
  void _onEnrollmentCreated(BuildContext context, EnrollmentState state) {
    final createdEnrollmentSummary = state.createdEnrollmentSummary;
    final nextIntent = _policy.resolveEffectiveIntent(
      baseIntent: _effectiveIntent,
      createdEnrollmentSummary: createdEnrollmentSummary,
    );

    if (nextIntent != _effectiveIntent) {
      setState(() => _effectiveIntent = nextIntent);
    }

    final enrollmentBloc = context.read<EnrollmentBloc>();
    _policy.requestLoad(enrollmentBloc, nextIntent, silent: true);
    enrollmentBloc.add(const EnrollmentSummariesRefreshRequested());

    if (widget.intent != nextIntent) {
      context.replace(nextIntent.toLocation(), extra: nextIntent);
    }

    enrollmentBloc.add(const EnrollmentCreateResultConsumed());
  }

  // Conserve les ids client (au démarrage) puis le détail local (après chaque
  // écriture d'étape) pour reconstruire l'agrégat NEW sans GET serveur.
  void _onDraftAggregateState(
    BuildContext context,
    EnrollmentDraftState state,
  ) {
    if (state is EnrollmentDraftStarted) {
      setState(
        () => _draftIds = DraftIds(
          enrollmentId: state.enrollmentId,
          studentId: state.studentId,
        ),
      );
    } else if (state is EnrollmentDraftDetailLoaded) {
      setState(() => _draftLocal = state.detail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isNewOffline) {
      return _buildNewOffline(context, l10n);
    }
    return _buildServer(context, l10n);
  }

  Widget _buildServer(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: BlocSelector<EnrollmentBloc, EnrollmentState, String>(
          selector: (state) {
            final detail = _policy.detail(state);
            if (detail == null) {
              return l10n.enrollmentUnknownStudent;
            }

            return _buildStudentDisplayName(detail);
          },
          builder: (context, studentDisplayName) {
            return EnrollmentJourneyAppBar(
              modeLabel: _buildJourneyModeLabel(l10n),
              studentDisplayName: studentDisplayName,
              currentStep: _currentStep,
              totalSteps: EnrollmentWizardStep.values.length,
            );
          },
        ),
      ),
      body: BlocListener<EnrollmentBloc, EnrollmentState>(
        listenWhen: _isEnrollmentCreated,
        listener: _onEnrollmentCreated,
        child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
          buildWhen: _shouldRebuildEnrollmentDetail,
          builder: (context, state) {
            final loadStatus = _policy.loadStatus(state);
            final detail = _policy.detail(state);

            if (loadStatus == EnrollmentLoadStatus.loading) {
              return const EnrollmentDetailPageStateShell(
                child: EnrollmentDetailLoadingTemplate(),
              );
            }

            if (loadStatus == EnrollmentLoadStatus.failure) {
              return EnrollmentDetailPageStateShell(
                child: EnrollmentDetailErrorTemplate(
                  message:
                      state.errorMessage ??
                      l10n.enrollmentDetailLoadErrorFallback,
                  onRetry: _requestDetail,
                ),
              );
            }

            if (detail == null) {
              return const EnrollmentDetailPageStateShell(
                child: EnrollmentDetailEmptyTemplate(),
              );
            }

            return EnrollmentDetailContentShell(
              child: EnrollmentStepperScope(
                enrollmentDetail: detail,
                detailIntent: _effectiveIntent,
                detailPolicy: _policy,
                onStepChanged: _onStepChanged,
              ),
            );
          },
        ),
      ),
    );
  }

  // Parcours NEW : agrégat reconstruit depuis le brouillon local (mapper) ou une
  // amorce vide + année courante avant la 1re étape. Aucun appel serveur.
  Widget _buildNewOffline(BuildContext context, AppLocalizations l10n) {
    return BlocListener<EnrollmentDraftBloc, EnrollmentDraftState>(
      listenWhen: (previous, current) =>
          previous != current &&
          (current is EnrollmentDraftStarted ||
              current is EnrollmentDraftDetailLoaded),
      listener: _onDraftAggregateState,
      child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
        builder: (context, bootstrapState) {
          final detail = _resolveNewOfflineDetail(bootstrapState.bootstrap);
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: EnrollmentJourneyAppBar(
                modeLabel: _buildJourneyModeLabel(l10n),
                studentDisplayName: _newOfflineDisplayName(detail, l10n),
                currentStep: _currentStep,
                totalSteps: EnrollmentWizardStep.values.length,
              ),
            ),
            body: detail == null
                ? const EnrollmentDetailPageStateShell(
                    child: EnrollmentDetailLoadingTemplate(),
                  )
                : EnrollmentDetailContentShell(
                    child: EnrollmentStepperScope(
                      enrollmentDetail: detail,
                      detailIntent: _effectiveIntent,
                      detailPolicy: _policy,
                      onStepChanged: _onStepChanged,
                    ),
                  ),
          );
        },
      ),
    );
  }

  EnrollmentDetail? _resolveNewOfflineDetail(Bootstrap? bootstrap) {
    final local = _draftLocal;
    final ids = _draftIds;

    if (_cachedAggregate != null &&
        identical(_cachedLocal, local) &&
        identical(_cachedIds, ids) &&
        identical(_cachedBootstrap, bootstrap)) {
      return _cachedAggregate;
    }

    final aggregate = _composeNewOfflineDetail(local, ids, bootstrap);
    _cachedLocal = local;
    _cachedIds = ids;
    _cachedBootstrap = bootstrap;
    _cachedAggregate = aggregate;
    return aggregate;
  }

  EnrollmentDetail? _composeNewOfflineDetail(
    LocalEnrollmentDetail? local,
    DraftIds? ids,
    Bootstrap? bootstrap,
  ) {
    if (local != null) {
      return mapLocalToEnrollmentDetail(
        local,
        levels: schoolLevelsFromBootstrap(bootstrap),
        groups: schoolLevelGroupsFromBootstrap(bootstrap),
      );
    }

    if (ids != null && bootstrap != null) {
      return buildDraftSeedDetail(
        enrollmentId: ids.enrollmentId,
        studentId: ids.studentId,
        academicYearId: bootstrap.academicYear.id,
      );
    }

    return null;
  }

  String _newOfflineDisplayName(
    EnrollmentDetail? detail,
    AppLocalizations l10n,
  ) {
    if (detail == null) {
      return l10n.enrollmentUnknownStudent;
    }
    final name = _buildStudentDisplayName(detail);
    return name.trim().isEmpty ? l10n.enrollmentUnknownStudent : name;
  }

  bool _isEnrollmentCreated(EnrollmentState previous, EnrollmentState current) {
    return previous.createStatus != current.createStatus &&
        current.createStatus == EnrollmentLoadStatus.success;
  }

  /// Rebuild detail UI only when fields used by the screen rendering changed.
  bool _shouldRebuildEnrollmentDetail(
    EnrollmentState previous,
    EnrollmentState current,
  ) {
    return _policy.loadStatus(previous) != _policy.loadStatus(current) ||
        _policy.detail(previous) != _policy.detail(current) ||
        previous.errorMessage != current.errorMessage;
  }

  String _buildStudentDisplayName(EnrollmentDetail detail) {
    final fullName = [
      detail.studentDetail.firstName,
      detail.studentDetail.lastName,
      detail.studentDetail.surname,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return fullName.isNotEmpty
        ? fullName
        : detail.enrollmentDetail.enrollmentCode;
  }

  String _buildJourneyModeLabel(AppLocalizations l10n) {
    return switch (_effectiveIntent.origin) {
      EnrollmentDetailOrigin.newFirstRegistration => l10n.journeyModeNew,
      EnrollmentDetailOrigin.firstRegistration => l10n.journeyModeEdit,
      EnrollmentDetailOrigin.preRegistration ||
      EnrollmentDetailOrigin.reRegistration => l10n.journeyModeView,
    };
  }

  void _onStepChanged(int step) {
    if (_currentStep == step || !mounted) {
      return;
    }
    setState(() => _currentStep = step);
  }
}
