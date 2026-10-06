import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/helpers/support_contact.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_title.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/common/eval_sticky_bottom_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_back_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_summary_card.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval_detail/eval_detail_action_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/eval_saisie_results_error_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_editor.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_editor_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_read_view.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_section.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page de pilotage d'une évaluation (spec S1) : en-tête résumé, puis le
/// sujet, la copie et la publication, et la barre d'actions collante. La
/// saisie des notes a sa propre page ([onOpenSaisie], qui reçoit l'en-tête à
/// jour — un maximum ajusté borne la saisie).
class EvalDetailPage extends StatelessWidget {
  final EvalDetailArgs args;
  final VoidCallback onBack;
  final ValueChanged<EvalDetailArgs> onOpenSaisie;

  const EvalDetailPage({
    super.key,
    required this.args,
    required this.onBack,
    required this.onOpenSaisie,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EvalDetailBloc>(
      create: (_) =>
          GetIt.instance<EvalDetailBloc>()
            ..add(EvalDetailRequested(args.eval.id)),
      child: _EvalDetailView(
        args: args,
        onBack: onBack,
        onOpenSaisie: onOpenSaisie,
      ),
    );
  }
}

class _EvalDetailView extends StatefulWidget {
  final EvalDetailArgs args;
  final VoidCallback onBack;
  final ValueChanged<EvalDetailArgs> onOpenSaisie;

  const _EvalDetailView({
    required this.args,
    required this.onBack,
    required this.onOpenSaisie,
  });

  @override
  State<_EvalDetailView> createState() => _EvalDetailViewState();
}

class _EvalDetailViewState extends State<_EvalDetailView> {
  /// Brouillon de l'éditeur du sujet ; `null` hors édition.
  SujetDraftController? _draft;

  EvalDetailArgs get _args => widget.args;

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  /// En-tête relu : avancement local et maximum ajusté.
  EvalDetailArgs _effectiveArgs(EvalDetailState state) {
    if (state.status != EvalDetailStatus.ready) return _args;
    final eval = _args.eval.withProgress(
      saisies: state.progress.saisies,
      total: state.progress.total,
    );
    return _args.copyWith(eval: eval.copyWith(maxPoints: state.maxPoints));
  }

  void _startEdit(EvalDetailState state, double maxPoints) => setState(() {
    _draft = SujetDraftController(
      initial: state.sujet,
      maxPoints: maxPoints,
      newId: GetIt.instance<IdGenerator>().newId,
    );
  });

  void _closeEditor() {
    final draft = _draft;
    setState(() => _draft = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => draft?.dispose());
  }

  void _save() {
    final draft = _draft;
    if (draft == null) return;
    context.read<EvalDetailBloc>().add(
      EvalDetailSujetSaveRequested(
        evaluationId: _args.eval.id,
        cadre: draft.cadre,
        questions: draft.questionValues,
        maxPoints: draft.adjustedMax,
      ),
    );
  }

  void _onSaveOutcome(BuildContext context, EvalDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.sujetSave) {
      case SujetSaveStatus.saved:
        final draft = _draft;
        if (draft != null) {
          AppSnackBar.showSuccess(
            context,
            l10n.sujetSavedToast(
              sujetSummary(
                l10n,
                questionCount: state.sujet.questions.length,
                bareme: draft.bareme,
              ),
            ),
          );
        }
        _closeEditor();
      case SujetSaveStatus.failed:
        AppSnackBar.showError(context, l10n.sujetSaveError);
      case SujetSaveStatus.idle || SujetSaveStatus.saving:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EvalDetailBloc, EvalDetailState>(
      listenWhen: (prev, curr) => prev.sujetSave != curr.sujetSave,
      listener: _onSaveOutcome,
      builder: (context, state) {
        final args = _effectiveArgs(state);
        return AppPageBackground(
          scrollable: true,
          bottomNavigationBar: _bottomBar(state, args),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EvalBackBar(
                brancheNom: args.brancheNom,
                classroomName: args.classroomName,
                evalName: evalDisplayName(context, args.eval),
                onBack: widget.onBack,
              ),
              const SizedBox(height: AppSpacing.lg),
              EvalSummaryCard(
                args: args,
                dureeMinutes: state.sujet.cadre.dureeMinutes,
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                alignment: Alignment.topCenter,
                child: _body(context, state, args),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _bottomBar(EvalDetailState state, EvalDetailArgs args) {
    if (state.status != EvalDetailStatus.ready) return null;
    final draft = _draft;
    return EvalStickyBottomBar(
      child: draft != null
          ? SujetEditorBar(
              draft: draft,
              saving: state.sujetSave == SujetSaveStatus.saving,
              onCancel: _closeEditor,
              onSave: _save,
            )
          : EvalDetailActionBar(
              progress: state.progress,
              onSaisir: () => widget.onOpenSaisie(args),
            ),
    );
  }

  Widget _body(
    BuildContext context,
    EvalDetailState state,
    EvalDetailArgs args,
  ) => switch (state.status) {
    EvalDetailStatus.loading => const EteeloListSkeleton(rowCount: 3),
    EvalDetailStatus.failure => EvalSaisieResultsErrorState.failure(
      failure: state.failure!,
      onRetry: () => context.read<EvalDetailBloc>().add(
        EvalDetailRequested(_args.eval.id),
      ),
      onReconnect: () =>
          context.read<AuthBloc>().add(const AuthLogoutRequested()),
      onContactAdmin: contactSupport,
    ),
    EvalDetailStatus.ready => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SujetSection(
          sujet: state.sujet,
          maxPoints: args.eval.maxPoints,
          // Ouverte si l'évaluation est à venir ou son sujet vide.
          initiallyExpanded:
              state.sujet.isEmpty || args.eval.state == EvalState.upcoming,
          onEdit: () => _startEdit(state, args.eval.maxPoints),
          readView: () => SujetReadView(
            sujet: state.sujet,
            onEdit: () => _startEdit(state, args.eval.maxPoints),
          ),
          editor: _draft == null
              ? null
              : SujetEditor(
                  draft: _draft!,
                  chapitres: args.eval.chapitres,
                  maxLocked: state.progress.maxLocked,
                ),
        ),
      ],
    ),
  };
}
