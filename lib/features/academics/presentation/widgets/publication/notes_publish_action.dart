import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/publication/publication_confirm.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Légende de la barre d'actions (spec S7) : où en est la publication des
/// notes.
String notesPublicationLegend(
  BuildContext context,
  NotesProgress progress,
  PublicationEtat? published,
) {
  final l10n = AppLocalizations.of(context)!;
  if (published != null) {
    return l10n.publicationNotesPublishedOn(
      MaterialLocalizations.of(
        context,
      ).formatCompactDate(published.publishedAt.toLocal()),
    );
  }
  return progress.isComplete
      ? l10n.publicationNotesReady
      : l10n.publicationNotesWaiting;
}

/// « Publier les notes », puis l'état « Notes publiées » (spec S7). Actif
/// quand toutes les notes sont posées et qu'aucune n'attend son envoi.
class NotesPublishAction extends StatelessWidget {
  final String evaluationId;
  final String classroomName;
  final NotesProgress progress;

  const NotesPublishAction({
    super.key,
    required this.evaluationId,
    required this.classroomName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate.access(
      kEvaluationPublishAccess,
      child: BlocBuilder<PublicationBloc, PublicationState>(
        builder: (context, state) {
          if (state.context.publications.notes != null) {
            return _published(l10n);
          }
          final ready =
              progress.isComplete &&
              !state.context.notesPending &&
              !state.context.evaluationPending;
          return SessionWriteGate(
            child: EteeloButton.primary(
              label: l10n.publicationPublishNotes,
              icon: Icons.send_rounded,
              fullWidth: false,
              isLoading: state.inFlight == PublicationKind.notes,
              onPressed: ready && state.inFlight == null
                  ? () => _publish(context)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _publish(BuildContext context) async {
    final bloc = context.read<PublicationBloc>();
    final confirmed = await confirmPublication(
      context,
      kind: PublicationKind.notes,
      effectif: progress.total,
      classroomName: classroomName,
    );
    if (confirmed) {
      bloc.add(
        PublicationPublishRequested(evaluationId, PublicationKind.notes),
      );
    }
  }

  Widget _published(AppLocalizations l10n) => Container(
    constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.academicsScoreGoodSoft,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.academicsScoreGood, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.academicsScoreGood,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.publicationNotesPublished,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.academicsScoreGood,
          ),
        ),
      ],
    ),
  );
}
