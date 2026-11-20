import 'dart:async';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_conflicts.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_consultation.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/copy_action.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/ended_gestures_notice.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_draft_section.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le contenu d'une classe choisie : les états vides, la version publiée en
/// semaine ou à la journée, ou le brouillon sous `schedule.write`.
class ClassTimetableContent extends StatelessWidget {
  final ClassTimetableState state;
  final ClassTimetableCubit cubit;
  final bool online;

  const ClassTimetableContent({
    super.key,
    required this.state,
    required this.cubit,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = state.view;
    if (state.classroomId == null) {
      return EteeloEmptyResult(
        label: l10n.classTimetablePickHint,
        medallionIcon: Icons.event_note_outlined,
        fullWidthCard: true,
      );
    }
    if (view == null) {
      return const EteeloListSkeleton(
        rowCount: 3,
        pillCount: 2,
        showAvatar: false,
      );
    }
    if (view.programme.isEmpty && view.published.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.classTimetableNoProgrammeTitle,
        description: l10n.classTimetableNoProgrammeBody(view.classroom.name),
        medallionIcon: Icons.menu_book_outlined,
        fullWidthCard: true,
      );
    }
    // Sans le droit d'agir, rien à construire : la page reste en lecture.
    final canWrite = PermissionGate.allows(context, const [Perm.scheduleWrite]);
    final ended = canWrite && view.ended.isNotEmpty
        ? EndedGesturesNotice(count: view.ended.length, cubit: cubit)
        : null;
    if (canWrite && view.hasDraft) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?ended,
          ClassTimetableSummary(
            view: view,
            cells: view.draft,
            conflicts: DraftConflicts.of(view).length,
          ),
          const SizedBox(height: AppSpacing.md),
          TimetableDraftSection(
            view: view,
            cubit: cubit,
            online: online,
            busy: state.busy,
          ),
        ],
      );
    }
    final start = canWrite && view.programme.isNotEmpty && !state.busy
        ? () => unawaited(_start(context))
        : null;
    if (view.published.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.classTimetableEmptyTitle(view.classroom.name),
        description: start == null ? l10n.classTimetableEmptyBody : null,
        medallionIcon: Icons.calendar_view_week_outlined,
        fullWidthCard: true,
        primaryAction: start == null
            ? null
            : PrimaryButton(
                label: l10n.classTimetableCreate,
                icon: Icons.add_rounded,
                fullWidth: false,
                onPressed: start,
              ),
        secondaryAction: start == null || !view.othersKnown
            ? null
            : SecondaryButton(
                label: l10n.classTimetableCopyFrom,
                icon: Icons.copy_all_outlined,
                fullWidth: false,
                onPressed: () => unawaited(copyTimetable(context, cubit)),
              ),
      );
    }
    return ClassTimetableConsultation(
      state: state,
      cubit: cubit,
      view: view,
      onEdit: start,
      ended: ended,
      online: online,
    );
  }

  /// « Modifier » / « Créer l'emploi du temps » (I7) : un brouillon commence,
  /// copie de la version publiée ou vide.
  Future<void> _start(BuildContext context) async {
    final result = await cubit.startDraft();
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.classTimetableSaveFailed,
      ),
      (_) {},
    );
  }
}
