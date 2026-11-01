import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
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
      ),
    );
  }

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
    if (state == AppLifecycleState.paused) _flush();
  }

  void _flush() => context.read<CoteSaveCubit>().flushNow();

  void _open(OfflineClassroom classroom) {
    final bloc = context.read<CoteSaisieBloc>();
    _classroomName = classroom.name;
    _flush();
    bloc.add(CoteSaisieOpened(classroom.id));
  }

  void _writeAddress(CoteSaisieReady state) {
    final router = _router;
    if (router == null) return;
    LocationQuery.write(router, {
      _classeParam: context.read<CoteSaisieBloc>().classroomId,
      _porteeParam: state.scope.portee.name,
      _cibleParam: state.scope.cibleId,
      _eleveParam: state.currentId,
    });
  }

  void _clearAddress() {
    final router = _router;
    if (router == null) return;
    LocationQuery.write(router, {
      _classeParam: null,
      _porteeParam: null,
      _cibleParam: null,
      _eleveParam: null,
    });
  }

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
    if (!previous.storageFailed && state.storageFailed) {
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
    return BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AcademicYearContextLoadStatus.success,
      listener: (context, state) => context.read<ClassroomOfflineBloc>().add(
        OfflineClassroomsRequested(
          academicYearId: state.context!.academicYear.id,
        ),
      ),
      child: Builder(builder: _content),
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

  void _reload(BuildContext context) {
    _flush();
    context.read<CoteSaisieBloc>().add(const CoteSaisieRetried());
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
            _StateListener(
              onChanged: _onStateChanged,
              child: _zone(context, state, classrooms),
            ),
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

/// Écoute les états avec le précédent en main, ce que `BlocListener` ne donne
/// qu'à son `listenWhen`.
class _StateListener extends StatefulWidget {
  final void Function(BuildContext, CoteSaisieState, CoteSaisieState) onChanged;
  final Widget child;

  const _StateListener({required this.onChanged, required this.child});

  @override
  State<_StateListener> createState() => _StateListenerState();
}

class _StateListenerState extends State<_StateListener> {
  late CoteSaisieState _previous = context.read<CoteSaisieBloc>().state;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoteSaisieBloc, CoteSaisieState>(
      listener: (context, state) {
        final previous = _previous;
        _previous = state;
        widget.onChanged(context, previous, state);
      },
      child: widget.child,
    );
  }
}
