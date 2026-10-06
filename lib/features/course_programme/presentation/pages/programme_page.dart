import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_back_bar.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_feedback_listener.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_launcher.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/programme_chapitres_card.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/programme_header_card.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_empty_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_failure_view.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le programme d'un cours (spec §2–3) : barre de retour, en-tête, chapitres
/// dans l'ordre de progression, FAB « Nouveau chapitre ». Lit le
/// [ProgrammeCubit] fourni par le parent ; les gestes d'écriture n'existent
/// qu'avec `academics.programme.write` ([ProgrammeWriteGate]).
class ProgrammePage extends StatelessWidget {
  final CoursDetailArgs cours;
  final VoidCallback onBack;
  final void Function(Chapitre chapitre) onOpenChapitre;

  const ProgrammePage({
    super.key,
    required this.cours,
    required this.onBack,
    required this.onOpenChapitre,
  });

  void _create(BuildContext context) => openChapitreForm(context, cours: cours);

  void _edit(BuildContext context, Chapitre chapitre) =>
      openChapitreForm(context, cours: cours, chapitre: chapitre);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProgrammeFeedbackListener(
      child: AppPageBackground(
        scrollable: true,
        floatingActionButton: _fab(context),
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

  /// « Nouveau chapitre » : seulement quand le programme a déjà un chapitre —
  /// vide, l'appel à l'action est dans l'état vide.
  Widget _fab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ProgrammeCubit, ProgrammeState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.programme?.isEmpty != curr.programme?.isEmpty,
      builder: (context, state) {
        final ready = state.status == ProgrammeStatus.ready;
        final programme = state.programme;
        if (!ready ||
            programme == null ||
            programme.isEmpty ||
            programme.readOnly) {
          return const SizedBox.shrink();
        }
        return ProgrammeWriteGate(
          child: EteeloFab(
            label: l10n.programmeFabNewChapitre,
            icon: Icons.add_rounded,
            onPressed: () => _create(context),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ProgrammeState state) {
    final programme = state.programme;
    if (state.status == ProgrammeStatus.failure || programme == null) {
      return state.status == ProgrammeStatus.loading
          ? const ProgrammeSkeleton()
          : ProgrammeFailureView(
              failure: state.failure,
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
          ProgrammeEmptyState(
            onCreate: programme.readOnly ? null : () => _create(context),
          )
        else
          ProgrammeChapitresCard(
            chapitres: programme.chapitres,
            onOpen: onOpenChapitre,
            readOnly: programme.readOnly,
            onMove: (chapitre, offset) => cubit.move(chapitre.id, offset),
            onEdit: (chapitre) => _edit(context, chapitre),
            onDelete: (chapitre) => _confirmDelete(context, chapitre),
          ),
      ],
    );
  }
}
