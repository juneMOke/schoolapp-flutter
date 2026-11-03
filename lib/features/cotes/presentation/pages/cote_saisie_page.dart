import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
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
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_saisie_address.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_query.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/selection/cote_scope_bar.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/selection/cote_selection_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/states/cote_saisie_states.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/workspace/cote_workspace.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_support.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résultats ▸ Saisie des notes. La classe, la portée, l'élève, la recherche
/// et le filtre de la liste vivent dans l'adresse ([CoteSaisieAddress]) : un
/// F5 les retrouve.
class CoteSaisiePage extends StatefulWidget {
  const CoteSaisiePage({super.key});

  @override
  State<CoteSaisiePage> createState() => _CoteSaisiePageState();
}

class _CoteSaisiePageState extends State<CoteSaisiePage>
    with WidgetsBindingObserver {
  GoRouter? _router;
  bool _openedFromAddress = false;
  String? _addressClassroomId;
  String _classroomName = '';
  CoteSaisieState _previous = const CoteSaisieIdle();

  /// La largeur reçue par la page (barre latérale déduite), relue à chaque
  /// mise en page : c'est elle, et non la fenêtre, qui dit « téléphone ».
  double? _width;

  /// La classe de l'adresse attend la première mesure pour s'ouvrir.
  bool _openPending = false;

  /// Le nombre de classes ouvertes : chacune replie la carte de sélection.
  int _openCount = 0;

  /// La recherche et le filtre de la liste : au-dessus d'elle, qui va et
  /// vient avec la largeur, et dans l'adresse.
  late CoteStudentQuery _studentQuery;

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
    _studentQuery = CoteSaisieAddress.queryOf(router)
      ..addListener(() => _write(CoteSaisieAddress.ofQuery(_studentQuery)));
    final classroomId = router == null
        ? null
        : LocationQuery.read(router, CoteSaisieAddress.classe);
    if (router == null || classroomId == null) return;
    _addressClassroomId = classroomId;
    _openPending = true;
  }

  /// Appelé à la mise en page : la largeur est enfin connue.
  void _openFromAddress() {
    final router = _router;
    final classroomId = _addressClassroomId;
    if (!_openPending || router == null || classroomId == null) return;
    _openPending = false;
    context.read<CoteSaisieBloc>().add(
      CoteSaisieOpened(
        classroomId,
        scope: CoteSaisieAddress.scopeOf(router),
        eleveId: LocationQuery.read(router, CoteSaisieAddress.eleve),
        singleColumn: _isPhone,
      ),
    );
  }

  bool get _isPhone =>
      (_width ?? MediaQuery.sizeOf(context).width) <
      AppBreakpoints.coteGridPhoneMax;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studentQuery.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `hidden` : l'onglet passe derrière (web), avant même `paused` — sur le
    // web, une fermeture n'arrive jamais jusqu'à `paused`.
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden) {
      return;
    }
    unawaited(_commitThenFlush());
  }

  void _flush() => context.read<CoteSaveCubit>().flushNow();

  /// La case en cours s'écrit en perdant le focus, puis la file part. Le
  /// focus ne change qu'au microtask suivant, et l'écriture passe par la
  /// file du bloc : la file n'est envoyée qu'une fois la case écrite, sans
  /// quoi la dernière cote attendrait la synchro suivante. Le bloc et le
  /// cubit sont lus avant d'attendre : la page a pu partir entre-temps.
  Future<void> _commitThenFlush() async {
    final bloc = context.read<CoteSaisieBloc>();
    final save = context.read<CoteSaveCubit>();
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.microtask(() {});
    await bloc.settled();
    if (!save.isClosed) unawaited(save.flushNow());
  }

  /// Une sortie (Précédent, un autre écran) pendant une frappe : la case
  /// s'écrit, puis la file part — aucune question, rien ne se perd.
  Future<bool> _commitBeforeLeaving() async {
    if (mounted) await _commitThenFlush();
    return true;
  }

  void _open(OfflineClassroom classroom) {
    final bloc = context.read<CoteSaisieBloc>();
    _classroomName = classroom.name;
    _flush();
    // Une autre classe, une autre liste : la recherche repart de zéro.
    _studentQuery.reset();
    _write({
      ...CoteSaisieAddress.cleared,
      CoteSaisieAddress.classe: classroom.id,
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
    CoteSaisieAddress.classe: context.read<CoteSaisieBloc>().classroomId,
    CoteSaisieAddress.portee: state.scope.portee.name,
    CoteSaisieAddress.cible: state.scope.cibleId,
    CoteSaisieAddress.eleve: state.currentId,
  });

  void _clearAddress() {
    _studentQuery.reset();
    _write(CoteSaisieAddress.cleared);
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
      _openCount++;
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
    final page = BlocListener<CoteSaisieBloc, CoteSaisieState>(
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
    // Une frappe en cours, que rien n'a écrite : sur le web, fermer ou
    // recharger l'onglet demande confirmation ; une sortie dans l'appli
    // écrit la case avant de partir. Seule la garde se relit — la page ne
    // se rebâtit pas à chaque frappe.
    final uncommitted = context.read<CoteSaisieBloc>().uncommittedCell;
    final guarded = ValueListenableBuilder<bool>(
      valueListenable: uncommitted,
      child: page,
      builder: (context, _, page) => RouteExitGuard(
        hasUnsavedWork: () => uncommitted.value,
        confirmExit: _commitBeforeLeaving,
        child: page!,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        _openFromAddress();
        return guarded;
      },
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
              openCount: _openCount,
              summary: ready == null
                  ? null
                  : _summary(context, ready, classrooms),
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

  /// « 7e A · Semestre 1 » ; la portée seule tant que la classe n'a pas de nom.
  String _summary(
    BuildContext context,
    CoteSaisieReady ready,
    ClassroomOfflineState classrooms,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameOf(
      classrooms,
      context.read<CoteSaisieBloc>().classroomId,
    );
    final scope = CoteLabels.scope(
      l10n,
      ready.classe,
      ready.scope,
      ready.columns,
    );
    return name.isEmpty ? scope : l10n.coteSelectionSummary(name, scope);
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
        studentQuery: _studentQuery,
      ),
    };
  }
}
