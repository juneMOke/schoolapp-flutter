import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_back_bar.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/programme_chapitres_card.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/programme_header_card.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_empty_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_error_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le programme d'un cours (spec §2–3) : barre de retour, en-tête, chapitres
/// dans l'ordre de progression. Lit le [ProgrammeCubit] fourni par le parent.
///
/// [onCreate] / [onEdit] ouvrent la modale du chapitre ; `null`, la page est en
/// lecture seule.
class ProgrammePage extends StatelessWidget {
  final CoursDetailArgs cours;
  final VoidCallback onBack;
  final void Function(Chapitre chapitre) onOpenChapitre;
  final VoidCallback? onCreate;
  final void Function(Chapitre chapitre)? onEdit;
  final Widget? floatingActionButton;

  const ProgrammePage({
    super.key,
    required this.cours,
    required this.onBack,
    required this.onOpenChapitre,
    this.onCreate,
    this.onEdit,
    this.floatingActionButton,
  });

  Future<void> _confirmDelete(BuildContext context, Chapitre chapitre) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ProgrammeCubit>();
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.programmeDeleteTitle,
      message: l10n.programmeDeleteMessage(chapitre.titre),
      confirmLabel: l10n.programmeDeleteConfirm,
      cancelLabel: l10n.cancel,
      isDestructive: true,
      confirmIcon: Icons.delete_outline_rounded,
    );
    if (!context.mounted || !confirmed) return;
    await cubit.delete(chapitre.id);
  }

  void _onFeedback(BuildContext context, ProgrammeState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.feedback?.kind) {
      case ProgrammeFeedbackKind.chapitreDeleted:
        AppSnackBar.showSuccess(context, l10n.programmeChapitreDeleted);
      case ProgrammeFeedbackKind.writeFailed:
        AppSnackBar.showError(context, l10n.programmeWriteFailed);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<ProgrammeCubit, ProgrammeState>(
      listenWhen: (prev, curr) =>
          curr.feedback != null && prev.feedback != curr.feedback,
      listener: _onFeedback,
      child: AppPageBackground(
        scrollable: true,
        floatingActionButton: floatingActionButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoursBackBar(
              brancheNom: cours.brancheNom,
              classroomName: cours.classroomName,
              backLabel: l10n.programmeBackToCourses,
              onBack: onBack,
            ),
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<ProgrammeCubit, ProgrammeState>(
              buildWhen: (prev, curr) =>
                  prev.status != curr.status ||
                  prev.programme != curr.programme,
              builder: (context, state) => AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.outCurve,
                switchOutCurve: AppMotion.inCurve,
                child: KeyedSubtree(
                  key: ValueKey<ProgrammeStatus>(state.status),
                  child: _body(context, state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ProgrammeState state) {
    final programme = state.programme;
    if (state.status == ProgrammeStatus.failure || programme == null) {
      return state.status == ProgrammeStatus.loading
          ? const ProgrammeSkeleton()
          : ProgrammeResultsErrorState(
              onRetry: () => context.read<ProgrammeCubit>().load(),
            );
    }
    final cubit = context.read<ProgrammeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgrammeHeaderCard(
          cours: cours,
          stats: programme.stats,
          evaluationsCount: programme.evaluationsCount,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (programme.isEmpty)
          ProgrammeEmptyState(onCreate: onCreate)
        else
          ProgrammeChapitresCard(
            chapitres: programme.chapitres,
            onOpen: onOpenChapitre,
            onMove: (chapitre, offset) => cubit.move(chapitre.id, offset),
            onEdit: onEdit,
            onDelete: (chapitre) => _confirmDelete(context, chapitre),
          ),
      ],
    );
  }
}
