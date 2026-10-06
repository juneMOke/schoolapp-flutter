import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_state.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_pdf.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_title.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/copie/copie_section.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/publication/publication_feedback.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/publication/publication_section.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_editor.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_read_view.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_rejection_banner.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_section.dart';

/// Les sections empilées du détail d'une évaluation (spec S1) : Sujet,
/// Copie, Publication aux parents.
class EvalDetailSections extends StatelessWidget {
  final EvalDetailArgs args;
  final EvalDetailState state;

  /// Brouillon du sujet en cours d'édition ; `null` en lecture.
  final SujetDraftController? draft;
  final VoidCallback onEditSujet;

  const EvalDetailSections({
    super.key,
    required this.args,
    required this.state,
    required this.draft,
    required this.onEditSujet,
  });

  @override
  Widget build(BuildContext context) {
    final eval = args.eval;
    final sujet = state.sujet;
    return PublicationFeedback(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SujetSection(
            sujet: sujet,
            maxPoints: eval.maxPoints,
            // Ouverte si l'évaluation est à venir ou son sujet vide.
            initiallyExpanded:
                sujet.isEmpty || eval.state == EvalState.upcoming,
            onEdit: onEditSujet,
            readView: () => SujetReadView(sujet: sujet, onEdit: onEditSujet),
            notice: sujet.envoi == SujetEnvoi.refuse
                ? SujetRejectionBanner(
                    code: sujet.rejectionCode,
                    onResendWithoutMax: () => context
                        .read<EvalDetailBloc>()
                        .add(EvalDetailSujetResendRequested(eval.id)),
                  )
                : null,
            editor: draft == null
                ? null
                : SujetEditor(
                    draft: draft!,
                    chapitres: eval.chapitres,
                    maxLocked: state.progress.maxLocked,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<CopieBloc, CopieState>(
            builder: (context, copie) => CopieSection(
              content: SujetCopieContent(
                brancheNom: args.brancheNom,
                classroomName: args.classroomName,
                titre: evalDisplayName(context, eval),
                dateLabel: formatEvalDate(context, eval.date),
                maxPoints: eval.maxPoints,
                sujet: sujet,
              ),
              state: copie,
              onDiffused: (d) => context.read<CopieBloc>().add(
                CopieDiffused(
                  evaluationId: eval.id,
                  kind: d.kind,
                  corrige: d.corrige,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PublicationSection(
            args: args,
            hasQuestions: !sujet.isEmpty,
            progress: state.progress,
          ),
        ],
      ),
    );
  }
}
