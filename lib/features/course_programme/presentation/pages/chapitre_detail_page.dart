import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_file_preview.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_back_bar.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/contenu/chapitre_contenu_section.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_blank_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_evaluations_section.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_header_card.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_notes_section.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_objectifs_section.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_ressources_section.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_strategies_section.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_launcher.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_error_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Le détail d'un chapitre (spec §7–9) : en-tête, contenu rédigé, puis
/// Objectifs, Stratégies, Notes, et la grille Ressources | Évaluations liées. Lit le
/// [ChapitreCubit] fourni par le parent ; modifier passe par la modale du
/// programme.
class ChapitreDetailPage extends StatelessWidget {
  final CoursDetailArgs cours;
  final String titre;
  final List<SousPeriodeOption> sousPeriodes;
  final VoidCallback onBack;
  final VoidCallback onOpenEvaluations;

  /// Un identifiant neuf (bloc de contenu).
  final String Function() newId;

  const ChapitreDetailPage({
    super.key,
    required this.cours,
    required this.titre,
    required this.sousPeriodes,
    required this.onBack,
    required this.onOpenEvaluations,
    required this.newId,
  });

  static const double _gridColumnMin = 280;

  Future<void> _edit(BuildContext context, ChapitreDetail detail) async {
    final cubit = context.read<ChapitreCubit>();
    await openChapitreForm(context, cours: cours, chapitre: detail.chapitre);
    await cubit.refresh();
  }

  Future<void> _open(BuildContext context, ChapitreRessource ressource) async {
    final l10n = AppLocalizations.of(context)!;
    if (ressource.type == RessourceType.lien) {
      final uri = Uri.tryParse(ressource.url ?? '');
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    final result = await context.read<ChapitreCubit>().openDocument(ressource);
    if (!context.mounted) return;
    await result.fold(
      (_) async =>
          AppSnackBar.showError(context, l10n.chapitreRessourceUnavailable),
      (bytes) async {
        final shown = await showEteeloFilePreview(
          context,
          title: ressource.nom,
          bytes: bytes,
          mimeType: ressource.mimeType ?? '',
          fileName: ressource.fileName ?? ressource.nom,
        );
        if (!shown && context.mounted) {
          AppSnackBar.showInfo(context, l10n.chapitreRessourceNotPreviewable);
        }
      },
    );
  }

  void _onFeedback(BuildContext context, ChapitreState state) {
    final l10n = AppLocalizations.of(context)!;
    final feedback = state.feedback;
    switch (feedback?.kind) {
      case ChapitreFeedbackKind.noteAdded:
        AppSnackBar.showSuccess(context, l10n.chapitreNoteAdded);
      case ChapitreFeedbackKind.noteDeleted:
        final noteId = feedback!.noteId!;
        final cubit = context.read<ChapitreCubit>();
        AppSnackBar.showSuccess(
          context,
          l10n.chapitreNoteDeleted,
          actionLabel: l10n.chapitreNoteUndo,
          onAction: () => cubit.undoNoteDeletion(noteId),
          duration: AppSnackBar.undoDuration,
        );
      case ChapitreFeedbackKind.contentSaved:
        AppSnackBar.showSuccess(context, l10n.chapitreContenuSaved);
      case ChapitreFeedbackKind.writeFailed:
        AppSnackBar.showError(context, l10n.programmeWriteFailed);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<ChapitreCubit, ChapitreState>(
      listenWhen: (prev, curr) =>
          curr.feedback != null && prev.feedback != curr.feedback,
      listener: _onFeedback,
      child: AppPageBackground(
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocSelector<ChapitreCubit, ChapitreState, String>(
              selector: (state) => state.detail?.chapitre.titre ?? titre,
              builder: (context, current) => CoursBackBar(
                brancheNom: cours.brancheNom,
                classroomName: cours.classroomName,
                backLabel: l10n.chapitreFormEyebrow(
                  cours.brancheNom,
                  cours.classroomName,
                ),
                crumb: current,
                onBack: onBack,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<ChapitreCubit, ChapitreState>(
              buildWhen: (prev, curr) =>
                  prev.status != curr.status ||
                  prev.detail != curr.detail ||
                  prev.hiddenNotes != curr.hiddenNotes,
              builder: (context, state) => AnimatedSwitcher(
                duration: AppMotion.standard,
                child: KeyedSubtree(
                  key: ValueKey<ChapitreStatus>(state.status),
                  child: _body(context, state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ChapitreState state) {
    final l10n = AppLocalizations.of(context)!;
    final detail = state.detail;
    if (detail == null) {
      return state.status == ChapitreStatus.loading
          ? ProgrammeSkeleton(semanticsLabel: l10n.chapitreLoadingA11yLabel)
          : ProgrammeResultsErrorState(
              title: l10n.chapitreErrorTitle,
              message: l10n.chapitreErrorMessage,
              onRetry: () => context.read<ChapitreCubit>().load(),
            );
    }
    final cubit = context.read<ChapitreCubit>();
    final chapitre = detail.chapitre;
    final canWrite =
        !chapitre.awaitingDownload && ProgrammeWriteGate.allows(context);
    final notes = [
      for (final note in chapitre.notes)
        if (!state.hiddenNotes.contains(note.id)) note,
    ];
    const gap = SizedBox(height: AppSpacing.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapitreHeaderCard(
          chapitre: chapitre,
          numero: detail.numero,
          cours: cours,
          sousPeriodes: sousPeriodes,
          onEdit: () => _edit(context, detail),
          onStatut: cubit.setStatut,
        ),
        gap,
        if (chapitre.isBlank) ...[
          ChapitreBlankState(
            onComplete: canWrite ? () => _edit(context, detail) : null,
          ),
          gap,
        ],
        ChapitreContenuSection(
          blocs: chapitre.blocs,
          canWrite: canWrite,
          newId: newId,
          onSave: cubit.saveBlocs,
        ),
        gap,
        if (!chapitre.isBlank) ...[
          ChapitreObjectifsSection(
            objectifs: chapitre.objectifs,
            onToggle: canWrite ? cubit.toggleObjectif : null,
          ),
          gap,
          ChapitreStrategiesSection(strategies: chapitre.strategies),
          gap,
        ],
        ChapitreNotesSection(
          notes: notes,
          onAdd: cubit.addNote,
          onDelete: cubit.requestNoteDeletion,
        ),
        gap,
        _grid(
          ChapitreRessourcesSection(
            ressources: chapitre.ressources,
            onOpen: (ressource) => _open(context, ressource),
          ),
          ChapitreEvaluationsSection(
            evaluations: detail.evaluations,
            onOpen: onOpenEvaluations,
          ),
        ),
      ],
    );
  }

  /// Ressources | Évaluations côte à côte dès que deux colonnes de 280 dp
  /// tiennent ; l'une sous l'autre sinon.
  Widget _grid(Widget left, Widget right) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < _gridColumnMin * 2 + AppSpacing.lg) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            const SizedBox(height: AppSpacing.lg),
            right,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right),
        ],
      );
    },
  );
}
