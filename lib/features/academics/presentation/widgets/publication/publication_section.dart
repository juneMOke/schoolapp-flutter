import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/publication_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval_detail/eval_section_card.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/publication/publication_confirm.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/publication/publication_row.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Publication aux parents » (spec S6) : le sujet du devoir et le
/// corrigé. Réservée à l'enseignant du cours et à la direction.
class PublicationSection extends StatelessWidget {
  final EvalDetailArgs args;
  final bool hasQuestions;
  final NotesProgress progress;

  const PublicationSection({
    super.key,
    required this.args,
    required this.hasQuestions,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionGate.access(
      kEvaluationPublishAccess,
      child: BlocBuilder<PublicationBloc, PublicationState>(
        builder: (context, state) => _section(context, state),
      ),
    );
  }

  Widget _section(BuildContext context, PublicationState state) {
    final l10n = AppLocalizations.of(context)!;
    final publications = state.context.publications;
    final pending = publicationPendingReason(l10n, state.context);
    final isDevoir = args.eval.type == TypeEvaluation.devoir;
    final noQuestion = hasQuestions ? null : l10n.copieNeedsQuestion;
    final incomplete = progress.isComplete
        ? null
        : l10n.publicationCorrigeWaiting(progress.saisies, progress.total);
    return EvalSectionCard(
      title: l10n.publicationSectionTitle,
      subtitle: publications.sujet != null || publications.corrige != null
          ? l10n.publicationSubtitlePublished
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicationRow(
            title: l10n.publicationKindSujet,
            etat: publications.sujet,
            inClass: !isDevoir,
            busy: state.inFlight == PublicationKind.sujet,
            description: !isDevoir
                ? l10n.publicationSujetInClass
                : noQuestion ??
                      pending ??
                      l10n.publicationSujetDue(
                        formatEvalDate(context, args.eval.date),
                      ),
            onPublish: noQuestion == null && pending == null
                ? () => _publish(context, PublicationKind.sujet)
                : null,
            onWithdraw: () => _withdraw(context, PublicationKind.sujet),
          ),
          const Divider(height: 1, color: AppColors.border),
          PublicationRow(
            title: l10n.publicationKindCorrige,
            etat: publications.corrige,
            busy: state.inFlight == PublicationKind.corrige,
            description: noQuestion ?? incomplete ?? pending,
            onPublish:
                noQuestion == null && incomplete == null && pending == null
                ? () => _publish(context, PublicationKind.corrige)
                : null,
            onWithdraw: () => _withdraw(context, PublicationKind.corrige),
          ),
        ],
      ),
    );
  }

  Future<void> _publish(BuildContext context, PublicationKind kind) async {
    final bloc = context.read<PublicationBloc>();
    final confirmed = await confirmPublication(
      context,
      kind: kind,
      effectif: progress.total,
      classroomName: args.classroomName,
    );
    if (confirmed) bloc.add(PublicationPublishRequested(args.eval.id, kind));
  }

  void _withdraw(BuildContext context, PublicationKind kind) => context
      .read<PublicationBloc>()
      .add(PublicationWithdrawRequested(args.eval.id, kind));
}
