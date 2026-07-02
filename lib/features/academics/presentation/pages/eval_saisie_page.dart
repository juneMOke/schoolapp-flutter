import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_back_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_summary_card.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_focus.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_mode_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_save_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_skeleton.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_table.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/eval_saisie_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page de saisie des notes d'une évaluation (spec §6–§10) : en-tête résumé +
/// panneau de saisie (bascule Tableau / Focus, brouillon partagé, barre
/// d'enregistrement collante). Fournit son propre `SaisieNotesBloc` et charge la
/// grille au montage ; l'en-tête provient de l'argument (pas de requête).
class EvalSaisiePage extends StatelessWidget {
  final EvalDetailArgs args;
  final VoidCallback onBack;

  const EvalSaisiePage({super.key, required this.args, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaisieNotesBloc>(
      create: (_) => GetIt.instance<SaisieNotesBloc>()
        ..add(
          NotesElevesLoaded(
            evaluationId: args.eval.id,
            maxPoints: args.eval.maxPoints,
          ),
        ),
      child: _EvalSaisieView(args: args, onBack: onBack),
    );
  }
}

class _EvalSaisieView extends StatefulWidget {
  final EvalDetailArgs args;
  final VoidCallback onBack;

  const _EvalSaisieView({required this.args, required this.onBack});

  @override
  State<_EvalSaisieView> createState() => _EvalSaisieViewState();
}

class _EvalSaisieViewState extends State<_EvalSaisieView> {
  final SaisieDraftController _draft = SaisieDraftController();
  SaisieMode _mode = SaisieMode.table;
  bool _initialized = false;
  bool _isSaving = false;
  Set<String> _savingBatch = {};

  String get _evalId => widget.args.eval.id;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _retry() {
    _initialized = false;
    context.read<SaisieNotesBloc>().add(
      NotesElevesLoaded(
        evaluationId: _evalId,
        maxPoints: widget.args.eval.maxPoints,
      ),
    );
  }

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
    if (!mounted)
      return; // garde mounted après await (règle non-négociable #8).
  }

  void _save() {
    // On écarte les ids vides : `SaisirNoteRequest.forStatut` lève sur un
    // studentId vide (le BLoC n'émet alors rien), ce qui figerait le lot.
    final ids = _draft.savableDirtyIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty || _isSaving) return;
    setState(() {
      _isSaving = true;
      _savingBatch = ids.toSet();
    });
    final bloc = context.read<SaisieNotesBloc>();
    for (final id in ids) {
      bloc.add(
        NoteSaisie(
          evaluationId: _evalId,
          studentId: id,
          statut: _draft.statutFor(id),
          pointsObtenus: _draft.pointsFor(id),
        ),
      );
    }
  }

  void _onState(BuildContext context, SaisieNotesState state) {
    // 1) Initialisation du brouillon dès que la grille est chargée (une fois).
    if (state.gridStatus == SaisieNotesGridStatus.loaded && !_initialized) {
      _initialized = true;
      _draft.initialize(state.rows, state.maxPoints);
    }
    // 2) Fin d'un lot d'enregistrement : on finalise quand CHAQUE ligne du lot a
    //    atteint un statut terminal (saved | error). On ne se contente pas de
    //    « aucune ligne en cours » : avec le transformer concurrent, une ligne
    //    encore `idle` (dont le handler n'a pas encore émis `saving`) serait à
    //    tort considérée comme terminée si une autre finit avant qu'elle démarre.
    if (_isSaving && _savingBatch.isNotEmpty) {
      final allDone = _savingBatch.every((id) {
        final row = state.rowFor(id);
        return row != null &&
            (row.saveStatus == RowSaveStatus.saved ||
                row.saveStatus == RowSaveStatus.error);
      });
      if (allDone) _finalizeSave(state);
    }
  }

  void _finalizeSave(SaisieNotesState state) {
    final l10n = AppLocalizations.of(context)!;
    final saved = <String>[];
    var anyError = false;
    for (final id in _savingBatch) {
      final row = state.rowFor(id);
      if (row == null) continue;
      if (row.saveStatus == RowSaveStatus.saved) {
        saved.add(id);
      } else if (row.saveStatus == RowSaveStatus.error) {
        anyError = true;
      }
    }
    _draft.commitSaved(saved, state.rows);
    setState(() {
      _isSaving = false;
      _savingBatch = {};
    });
    if (anyError) {
      AppSnackBar.showError(context, l10n.evalSaveErrorToast);
    } else {
      final notees = state.rows
          .where((r) => r.note.statut == StatutNote.notee)
          .length;
      final enAttente = state.rows
          .where(
            (r) =>
                r.note.statut == StatutNote.enAttente || r.note.statut == null,
          )
          .length;
      AppSnackBar.showSuccess(
        context,
        l10n.evalSaveSuccessToast(notees, enAttente),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      bottomNavigationBar: _StickySaveBar(
        draft: _draft,
        isSaving: _isSaving,
        onSave: _save,
      ),
      child: BlocConsumer<SaisieNotesBloc, SaisieNotesState>(
        listenWhen: (prev, curr) =>
            prev.gridStatus != curr.gridStatus || prev.rows != curr.rows,
        listener: _onState,
        buildWhen: (prev, curr) =>
            prev.gridStatus != curr.gridStatus ||
            prev.rows != curr.rows ||
            prev.gridErrorType != curr.gridErrorType,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EvalBackBar(
                brancheNom: widget.args.brancheNom,
                classroomName: widget.args.classroomName,
                evalName: widget.args.eval.nom,
                onBack: widget.onBack,
              ),
              const SizedBox(height: AppSpacing.lg),
              EvalSummaryCard(args: widget.args),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                alignment: Alignment.topCenter,
                child: _body(context, state),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, SaisieNotesState state) {
    return switch (state.gridStatus) {
      SaisieNotesGridStatus.initial ||
      SaisieNotesGridStatus.loading => const SaisieSkeleton(),
      SaisieNotesGridStatus.loadError => EvalSaisieResultsErrorState(
        type: state.gridErrorType,
        onRetry: _retry,
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        onContactAdmin: _contactAdmin,
      ),
      SaisieNotesGridStatus.loaded =>
        state.rows.isEmpty ? _empty(context) : _panel(state.rows),
    };
  }

  Widget _empty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.evalSaisieEmptyTitle,
      description: l10n.evalSaisieEmptyDescription,
      medallionIcon: Icons.groups_outlined,
      primaryAction: EteeloButton.primary(
        label: l10n.evalDetailBack,
        icon: Icons.arrow_back_rounded,
        onPressed: widget.onBack,
        fullWidth: false,
      ),
    );
  }

  Widget _panel(List<NoteEleveRow> rows) {
    final students = rows.map((r) => r.note).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaisieModeBar(
          mode: _mode,
          onModeChanged: (m) => setState(() => _mode = m),
          draft: _draft,
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: _mode == SaisieMode.table
              ? SaisieTable(
                  key: const ValueKey<String>('saisie-table'),
                  students: students,
                  draft: _draft,
                  inputsEnabled: !_isSaving,
                )
              : SaisieFocus(
                  key: const ValueKey<String>('saisie-focus'),
                  students: students,
                  draft: _draft,
                  inputsEnabled: !_isSaving,
                ),
        ),
      ],
    );
  }
}

/// Barre d'enregistrement collante (spec §10), placée dans le `bottomNavigationBar`
/// du Scaffold : visible uniquement quand la grille est chargée et non vide.
class _StickySaveBar extends StatelessWidget {
  final SaisieDraftController draft;
  final bool isSaving;
  final VoidCallback onSave;

  const _StickySaveBar({
    required this.draft,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaisieNotesBloc, SaisieNotesState>(
      buildWhen: (prev, curr) =>
          prev.gridStatus != curr.gridStatus ||
          prev.rows.isEmpty != curr.rows.isEmpty,
      builder: (context, state) {
        final ready =
            state.gridStatus == SaisieNotesGridStatus.loaded &&
            state.rows.isNotEmpty;
        if (!ready) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            // heightFactor: 1.0 → la barre s'ajuste à sa hauteur intrinsèque.
            // Sans lui, l'Align remplirait la contrainte lâche du
            // bottomNavigationBar (toute la hauteur d'écran) et masquerait le
            // corps + pousserait les toasts flottants hors écran.
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.detailContentMaxWidth,
                ),
                child: SaisieSaveBar(
                  draft: draft,
                  isSaving: isSaving,
                  onSave: onSave,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
