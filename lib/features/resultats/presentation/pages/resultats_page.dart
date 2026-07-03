import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultat_focus_args.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_search_mode.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_search_request.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_support.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultats_eleve_results.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultats_synthese_card.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultats_table.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_periode_bar.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_search_card.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_idle_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_results_empty_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_results_error_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_table_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page « Résultats ▸ Résultats par classe » (spec §00-05) : carte de recherche,
/// barre de période, puis la zone d'état (vue classe : synthèse + table, ou liste
/// de recherche par élève). Le clic mène à la vue focus via [onOpenFocus].
class ResultatsPage extends StatefulWidget {
  final ValueChanged<ResultatFocusArgs> onOpenFocus;

  const ResultatsPage({super.key, required this.onOpenFocus});

  @override
  State<ResultatsPage> createState() => _ResultatsPageState();
}

class _ResultatsPageState extends State<ResultatsPage> {
  ResultatsSearchMode _mode = ResultatsSearchMode.classe;
  Decoupage _currentDecoupage = Decoupage.unknown;

  /// Classe sélectionnée dans la cascade : détermine quelles périodes charger
  /// (endpoint scopé classe) et l'affichage de la barre de période.
  BootstrapClassroom? _currentClassroom;
  PeriodeScolaire? _selectedPeriode;

  /// Dernière recherche validée (mode courant conservé). Remis à `null` au
  /// changement de cycle pour éviter de réafficher/refetch une classe périmée.
  ResultatsSearchRequest? _submitted;

  /// Période à laquelle correspondent **les données de classe affichées** (≠
  /// [_selectedPeriode], la sélection vive) : garantit que les libellés et le
  /// drill-down focus ne devancent jamais les données chargées (revue §bug).
  PeriodeScolaire? _committedPeriode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bootstrap = context.watch<BootstrapCurrentYearBloc>().state.bootstrap;
    if (bootstrap == null) {
      return const AppPageBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final cycleOptions = ClassesListPageHelpers.buildCycleOptions(
      bootstrap.schoolLevelGroups,
    );
    final classeState = context.watch<ResultatsClasseBloc>().state;
    final eleveState = context.watch<EleveSearchBloc>().state;
    final isSubmitting = _mode == ResultatsSearchMode.classe
        ? classeState.status == ResultatsClasseStatus.loading
        : eleveState.status == EleveSearchStatus.loading;

    return AppPageBackground(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResultatsSearchCard(
            cycleOptions: cycleOptions,
            periodeSelected: _selectedPeriode != null,
            isSubmitting: isSubmitting,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onCycleChanged: (cycle) => _onCycleChanged(cycle, bootstrap),
            onClassroomChanged: _onClassroomChanged,
            onSubmit: _onSubmit,
          ),
          if (_currentClassroom != null) ...[
            const SizedBox(height: AppSpacing.md),
            ResultatsPeriodeBar(
              cycleDecoupage: _currentDecoupage,
              selectedPeriodeId: _selectedPeriode?.id,
              onSelect: _onPeriodeSelected,
              onRetry: _loadPeriodes,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          MultiBlocListener(
            listeners: [
              BlocListener<EleveSearchBloc, EleveSearchState>(
                listenWhen: (prev, curr) => prev.status != curr.status,
                listener: _onEleveSearchChanged,
              ),
              // Auto-sélection de la période « courante » à l'arrivée des périodes.
              BlocListener<PeriodesScolairesBloc, PeriodesScolairesState>(
                listenWhen: (prev, curr) => prev.status != curr.status,
                listener: _onPeriodesLoaded,
              ),
            ],
            child: _resultsZone(l10n, classeState, eleveState),
          ),
        ],
      ),
    );
  }

  // ── Zone d'état ────────────────────────────────────────────────────────────

  Widget _resultsZone(
    AppLocalizations l10n,
    ResultatsClasseState classeState,
    EleveSearchState eleveState,
  ) {
    if (_mode == ResultatsSearchMode.classe) {
      return _classeZone(l10n, classeState);
    }
    return _eleveZone(eleveState);
  }

  Widget _classeZone(AppLocalizations l10n, ResultatsClasseState state) {
    // La zone classe ne s'affiche que si la dernière recherche validée est une
    // recherche par classe (sinon idle) : évite d'afficher des données périmées
    // après un changement de cycle ou de mode (revue §bug).
    if (_submitted?.mode != ResultatsSearchMode.classe) {
      return const ResultatsIdleState();
    }
    switch (state.status) {
      case ResultatsClasseStatus.initial:
        return const ResultatsIdleState();
      case ResultatsClasseStatus.loading:
        return const ResultatsTableSkeleton();
      case ResultatsClasseStatus.empty:
        return const ResultatsResultsEmptyState(
          mode: ResultatsSearchMode.classe,
        );
      case ResultatsClasseStatus.failure:
        return ResultatsResultsErrorState(
          type: state.errorType,
          onRetry: _retryClasse,
          onReconnect: _reconnect,
          onContactAdmin: resultatsContactSupport,
        );
      case ResultatsClasseStatus.success:
        final resultats = state.resultats!;
        final periode = _committedPeriode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResultatsSyntheseCard(
              stats: resultats.stats,
              periodeLongLabel: periode == null
                  ? ''
                  : resultatsPeriodLong(l10n, periode),
            ),
            const SizedBox(height: AppSpacing.md),
            ResultatsTable(
              resultats: resultats,
              periodeShortLabel: periode == null
                  ? ''
                  : resultatsPeriodShort(l10n, periode),
              classroomLabel: _submitted?.classroomLabel ?? '',
              onOpenLigne: _openFocusFromLigne,
            ),
          ],
        );
    }
  }

  Widget _eleveZone(EleveSearchState state) {
    // Idem : ne montrer la liste élève que si la dernière recherche validée est
    // une recherche par élève (sinon idle).
    if (_submitted?.mode != ResultatsSearchMode.eleve) {
      return const ResultatsIdleState();
    }
    switch (state.status) {
      case EleveSearchStatus.initial:
        return const ResultatsIdleState();
      case EleveSearchStatus.loading:
        return const ResultatsTableSkeleton();
      case EleveSearchStatus.empty:
        return const ResultatsResultsEmptyState(
          mode: ResultatsSearchMode.eleve,
        );
      case EleveSearchStatus.failure:
        return ResultatsResultsErrorState(
          type: state.errorType,
          onRetry: _retryEleve,
          onReconnect: _reconnect,
          onContactAdmin: resultatsContactSupport,
        );
      case EleveSearchStatus.success:
        return ResultatsEleveResults(
          eleves: state.resultats,
          classroomLabel: _submitted?.classroomLabel ?? '',
          onOpenMember: _openFocusFromMember,
        );
    }
  }

  // ── Interactions ─────────────────────────────────────────────────────────

  void _onCycleChanged(ClassesListCycleOption? cycle, Bootstrap bootstrap) {
    // Le cycle ne fait que fixer le découpage (trimestres/semestres) : les
    // périodes se chargent à la sélection de la CLASSE (endpoint scopé classe).
    setState(() {
      _currentDecoupage = _decoupageFor(cycle, bootstrap);
      // La classe/période affichée devient invalide (le cycle a changé).
      _submitted = null;
      _committedPeriode = null;
    });
  }

  void _onClassroomChanged(BootstrapClassroom? classroom) {
    setState(() {
      _currentClassroom = classroom;
      _selectedPeriode = null;
      // La classe a changé → recherche/résultats précédents périmés.
      _submitted = null;
      _committedPeriode = null;
    });
    if (classroom != null) {
      _loadPeriodes();
    }
  }

  void _loadPeriodes() {
    final classroom = _currentClassroom;
    if (classroom == null) {
      return;
    }
    context.read<PeriodesScolairesBloc>().add(
      PeriodesScolairesRequested(classroomId: classroom.id),
    );
  }

  /// Présélectionne la période « courante » (spec) dès l'arrivée des périodes,
  /// si l'utilisateur n'a rien choisi. 0 période courante = normal (hors année).
  void _onPeriodesLoaded(BuildContext context, PeriodesScolairesState state) {
    if (state.status != PeriodesScolairesStatus.success ||
        _selectedPeriode != null) {
      return;
    }
    for (final periode in state.periodes) {
      if (periode.courant) {
        _onPeriodeSelected(periode);
        return;
      }
    }
  }

  void _onPeriodeSelected(PeriodeScolaire periode) {
    final effective = periode.decoupage == Decoupage.unknown
        ? _currentDecoupage
        : periode.decoupage;
    final normalized = PeriodeScolaire(
      id: periode.id,
      ordre: periode.ordre,
      decoupage: effective,
      statut: periode.statut,
      libelle: periode.libelle,
    );
    setState(() => _selectedPeriode = normalized);

    // Changement de grande période avec une classe déjà affichée → refetch (§01).
    // `_committedPeriode != null` garantit qu'une classe est bien affichée pour
    // le cycle courant (remis à null au changement de cycle) : pas de refetch
    // d'une classe périmée d'un autre cycle (revue §bug).
    final submitted = _submitted;
    if (_mode == ResultatsSearchMode.classe &&
        submitted?.mode == ResultatsSearchMode.classe &&
        _committedPeriode != null) {
      setState(() => _committedPeriode = normalized);
      context.read<ResultatsClasseBloc>().add(
        ResultatsClasseRequested(
          classroomId: submitted!.classroom.id,
          periodeScolaireId: normalized.id,
        ),
      );
    }
  }

  void _onSubmit(ResultatsSearchRequest request) {
    final periode = _selectedPeriode;
    if (periode == null) {
      return;
    }
    setState(() {
      _submitted = request;
      // La classe affichée correspond désormais à la période validée.
      _committedPeriode = request.mode == ResultatsSearchMode.classe
          ? periode
          : _committedPeriode;
    });

    if (request.mode == ResultatsSearchMode.classe) {
      context.read<ResultatsClasseBloc>().add(
        ResultatsClasseRequested(
          classroomId: request.classroom.id,
          periodeScolaireId: periode.id,
        ),
      );
    } else {
      context.read<EleveSearchBloc>().add(
        EleveSearchRequested(
          classroomId: request.classroom.id,
          academicYearId: _academicYearId(),
          nom: _nullable(request.nom),
          postnom: _nullable(request.postnom),
          prenom: _nullable(request.prenom),
        ),
      );
    }
  }

  void _onEleveSearchChanged(BuildContext context, EleveSearchState state) {
    // Un seul résultat élève → ouverture directe du focus (spec machine à états).
    if (state.status == EleveSearchStatus.success &&
        state.resultats.length == 1) {
      _openFocusFromMember(state.resultats.first);
    }
  }

  void _retryClasse() {
    final submitted = _submitted;
    final periode = _committedPeriode;
    if (submitted == null || periode == null) {
      return;
    }
    context.read<ResultatsClasseBloc>().add(
      ResultatsClasseRequested(
        classroomId: submitted.classroom.id,
        periodeScolaireId: periode.id,
      ),
    );
  }

  void _retryEleve() {
    final submitted = _submitted;
    if (submitted == null) {
      return;
    }
    context.read<EleveSearchBloc>().add(
      EleveSearchRequested(
        classroomId: submitted.classroom.id,
        academicYearId: _academicYearId(),
        nom: _nullable(submitted.nom),
        postnom: _nullable(submitted.postnom),
        prenom: _nullable(submitted.prenom),
      ),
    );
  }

  void _reconnect() =>
      context.read<AuthBloc>().add(const AuthLogoutRequested());

  // ── Ouverture du focus ─────────────────────────────────────────────────────

  void _openFocusFromLigne(ResultatEleveLigne ligne) {
    // Depuis la table : la période du drill-down = celle des données affichées.
    final args = _buildFocusArgs(
      periode: _committedPeriode,
      studentId: ligne.studentId,
      nom: ligne.nom,
      postnom: ligne.postnom,
      prenom: ligne.prenom,
      genre: ligne.genre,
    );
    if (args != null) {
      widget.onOpenFocus(args);
    }
  }

  void _openFocusFromMember(ClassroomMember member) {
    // Depuis la recherche élève : la liste ne dépend pas de la période →
    // on ouvre le focus sur la période sélectionnée courante.
    final args = _buildFocusArgs(
      periode: _selectedPeriode,
      studentId: member.studentId,
      nom: member.studentLastName,
      postnom: member.studentMiddleName,
      prenom: member.studentFirstName,
      genre: member.studentGender,
    );
    if (args != null) {
      widget.onOpenFocus(args);
    }
  }

  ResultatFocusArgs? _buildFocusArgs({
    required PeriodeScolaire? periode,
    required String studentId,
    required String nom,
    required String? postnom,
    required String prenom,
    required ClassroomMemberGender? genre,
  }) {
    final submitted = _submitted;
    if (submitted == null || periode == null) {
      return null;
    }
    final l10n = AppLocalizations.of(context)!;
    return ResultatFocusArgs(
      classroomId: submitted.classroom.id,
      periodeScolaireId: periode.id,
      studentId: studentId,
      nom: nom,
      postnom: postnom,
      prenom: prenom,
      genre: genre,
      classroomLabel: submitted.classroomLabel,
      periodeLabel: resultatsPeriodLong(l10n, periode),
    );
  }

  // ── Utilitaires ──────────────────────────────────────────────────────────

  Decoupage _decoupageFor(ClassesListCycleOption? cycle, Bootstrap bootstrap) {
    if (cycle == null) {
      return Decoupage.unknown;
    }
    for (final bundle in bootstrap.schoolLevelGroups) {
      if (bundle.schoolLevelGroup.id == cycle.id) {
        return DecoupageX.fromApiValue(bundle.schoolLevelGroup.periodType);
      }
    }
    return Decoupage.unknown;
  }

  String _academicYearId() =>
      context
          .read<BootstrapCurrentYearBloc>()
          .state
          .bootstrap
          ?.academicYear
          .id ??
      '';

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
}
