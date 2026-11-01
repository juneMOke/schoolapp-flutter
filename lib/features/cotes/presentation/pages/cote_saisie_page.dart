import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/selection/cote_scope_bar.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/selection/cote_selection_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/states/cote_saisie_states.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/workspace/cote_workspace.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_support.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résultats ▸ Saisie des notes. La classe, la portée et l'élève vivent dans
/// l'adresse (`?classe=…&portee=…&cible=…&eleve=…`) : un F5 les retrouve.
class CoteSaisiePage extends StatefulWidget {
  const CoteSaisiePage({super.key});

  @override
  State<CoteSaisiePage> createState() => _CoteSaisiePageState();
}

class _CoteSaisiePageState extends State<CoteSaisiePage>
    with WidgetsBindingObserver {
  static const _classeParam = 'classe';
  static const _porteeParam = 'portee';
  static const _cibleParam = 'cible';
  static const _eleveParam = 'eleve';

  GoRouter? _router;
  bool _openedFromAddress = false;
  String? _addressClassroomId;
  String _classroomName = '';
  CoteSaisieState _previous = const CoteSaisieIdle();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = LocationQuery.ownedBy(context);
    if (_openedFromAddress) return;
    _openedFromAddress = true;
    final router = _router;
    final classroomId = router == null
        ? null
        : LocationQuery.read(router, _classeParam);
    if (router == null || classroomId == null) return;
    _addressClassroomId = classroomId;
    context.read<CoteSaisieBloc>().add(
      CoteSaisieOpened(
        classroomId,
        scope: _scopeFromAddress(router),
        eleveId: LocationQuery.read(router, _eleveParam),
        singleColumn: _isPhone,
      ),
    );
  }

  bool get _isPhone =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.coteGridPhoneMax;

  CoteScope? _scopeFromAddress(GoRouter router) {
    final portee = CotePortee.values
        .where((p) => p.name == LocationQuery.read(router, _porteeParam))
        .firstOrNull;
    if (portee == null) return null;
    return CoteScope(
      portee: portee,
      cibleId: LocationQuery.read(router, _cibleParam),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    // La case en cours s'écrit en perdant le focus, puis la file part.
    FocusManager.instance.primaryFocus?.unfocus();
    _flush();
  }

  void _flush() => context.read<CoteSaveCubit>().flushNow();

  void _open(OfflineClassroom classroom) {
    final bloc = context.read<CoteSaisieBloc>();
    _classroomName = classroom.name;
    _flush();
    _write({
      _classeParam: classroom.id,
      _porteeParam: null,
      _cibleParam: null,
      _eleveParam: null,
    });
    bloc.add(CoteSaisieOpened(classroom.id, singleColumn: _isPhone));
  }

  /// Sans entrée d'historique : Précédent quitte l'écran, il ne rejoue pas les
  /// élèves un à un.
  void _write(Map<String, String?> values) {
    final router = _router;
    if (router == null) return;
    Router.neglect(context, () => LocationQuery.write(router, values));
  }

  void _writeAddress(CoteSaisieReady state) => _write({
    _classeParam: context.read<CoteSaisieBloc>().classroomId,
    _porteeParam: state.scope.portee.name,
    _cibleParam: state.scope.cibleId,
    _eleveParam: state.currentId,
  });

  void _clearAddress() => _write({
    _classeParam: null,
    _porteeParam: null,
    _cibleParam: null,
    _eleveParam: null,
  });

  void _announce(BuildContext context, CoteSaisieReady state) {
    final l10n = AppLocalizations.of(context)!;
    final percent = state.current.pct;
    final name = state.currentEleve.fullName;
    final index = state.currentIndex + 1;
    final total = state.eleves.length;
    final message = percent == null
        ? l10n.coteStudentAnnounceNoGrade(name, index, total)
        : state.current.provisoire
        ? l10n.coteStudentAnnounceProvisional(name, index, total, percent)
        : l10n.coteStudentAnnounce(name, index, total, percent);
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  void _onStateChanged(
    BuildContext context,
    CoteSaisieState previous,
    CoteSaisieState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state is CoteSaisieIdle) _clearAddress();
    if (state is! CoteSaisieReady) return;
    final bloc = context.read<CoteSaisieBloc>();
    if (previous is! CoteSaisieReady) {
      context.read<CoteSaveCubit>().attach(bloc.classroomId!);
      _writeAddress(state);
      return;
    }
    if (previous.currentId != state.currentId) {
      _writeAddress(state);
      _announce(context, state);
    } else if (previous.scope != state.scope) {
      _flush();
      _writeAddress(state);
    }
    if (previous.changedNotice != state.changedNotice) {
      AppSnackBar.showInfo(context, l10n.coteChangedNotice(state.changedCount));
    }
    if (previous.storageFailures != state.storageFailures) {
      AppSnackBar.showError(context, l10n.coteStorageFailed);
    }
  }

  String _nameOf(ClassroomOfflineState state, String? classroomId) {
    if (_classroomName.isNotEmpty) return _classroomName;
    return state.classrooms
            .where((c) => c.id == classroomId)
            .firstOrNull
            ?.name ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    // Posé ici, au-dessus de l'attente de l'année : un lien profond ouvre sa
    // classe avant que la page n'ait fini d'arriver, et l'enregistrement doit
    // tout de même s'y attacher.
    return BlocListener<CoteSaisieBloc, CoteSaisieState>(
      listenWhen: (previous, current) {
        _previous = previous;
        return true;
      },
      listener: (context, state) => _onStateChanged(context, _previous, state),
      child: BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == AcademicYearContextLoadStatus.success,
        listener: (context, state) => context.read<ClassroomOfflineBloc>().add(
          OfflineClassroomsRequested(
            academicYearId: state.context!.academicYear.id,
          ),
        ),
        child: Builder(builder: _content),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final yearContext = context.watch<AcademicYearContextBloc>().state.context;
    if (yearContext == null) {
      return const AppPageBackground(child: CoteSaisieSkeleton());
    }
    final classrooms = context.watch<ClassroomOfflineBloc>().state;
    final cycleOptions = ClassesListPageHelpers.buildCycleOptions(
      yearContext.schoolLevelGroups,
      classrooms.classrooms,
    );
    return AppPageBackground(
      width: PageContentWidth.wide,
      scrollable: true,
      child: PageActionShortcut(
        action: PageAction.refresh,
        onInvoke: () => _reload(context),
        child: _body(context, cycleOptions, classrooms),
      ),
    );
  }

  /// L'envoi d'abord : la réponse dira le serveur à jour.
  Future<void> _reload(BuildContext context) async {
    final bloc = context.read<CoteSaisieBloc>();
    await context.read<CoteSaveCubit>().flushNow();
    if (!mounted) return;
    bloc.add(const CoteSaisieRetried());
  }

  Widget _body(
    BuildContext context,
    List<ClassesListCycleOption> cycleOptions,
    ClassroomOfflineState classrooms,
  ) {
    return BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (previous is CoteSaisieReady &&
              current is CoteSaisieReady &&
              previous.scope != current.scope),
      builder: (context, state) {
        final ready = state is CoteSaisieReady ? state : null;
        final bloc = context.read<CoteSaisieBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoteSelectionCard(
              cycleOptions: cycleOptions,
              initialClassroomId: _addressClassroomId,
              isOpening: state is CoteSaisieLoading,
              onOpen: _open,
              scopeBar: ready == null
                  ? null
                  : CoteScopeBar(
                      classe: ready.classe,
                      scope: ready.scope,
                      year: ready.year,
                      onChanged: (scope) => bloc.add(CoteScopeChanged(scope)),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _zone(context, state, classrooms),
          ],
        );
      },
    );
  }

  Widget _zone(
    BuildContext context,
    CoteSaisieState state,
    ClassroomOfflineState classrooms,
  ) {
    final bloc = context.read<CoteSaisieBloc>();
    return switch (state) {
      CoteSaisieIdle() => const CoteSaisieIdleState(),
      CoteSaisieLoading() => const CoteSaisieSkeleton(),
      CoteSaisieEmpty(:final reason) => CoteSaisieEmptyState(
        reason: reason,
        onChangeClass: () => bloc.add(const CoteSaisieClosed()),
      ),
      CoteSaisieFailure(:final type, :final incidentCode) =>
        ResultatsResultsErrorState(
          type: type,
          incidentCode: incidentCode,
          onRetry: () => bloc.add(const CoteSaisieRetried()),
          onReconnect: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          onContactAdmin: resultatsContactSupport,
        ),
      CoteSaisieReady() => CoteWorkspace(
        classroomName: _nameOf(classrooms, bloc.classroomId),
        onStudentChanged: _flush,
      ),
    };
  }
}
