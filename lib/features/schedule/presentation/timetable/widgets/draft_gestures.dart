import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_conflicts.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_drop.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/publish_timetable_dialog.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/slot_options_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes du brouillon vus de l'écran : toucher un créneau (O2), déposer
/// (I9 à I11), abandonner (O5), publier (O4) — et leur compte rendu (A7).
class DraftGestures {
  final BuildContext context;
  final ClassTimetableView view;
  final ClassTimetableCubit cubit;

  const DraftGestures(this.context, {required this.view, required this.cubit});

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// O2 : le créneau touché (I8).
  Future<void> openSlot(Weekday day, TimeSlot slot) async {
    final current = [
      for (final c in view.draft)
        if (c.day == day && c.slotId == slot.id && !c.isEmpty) c,
    ].firstOrNull;
    final choice = await showEteeloAdaptiveSheet<SlotChoice>(
      context: context,
      builder: (_) => SlotOptionsSheet(
        view: view,
        day: day,
        slot: slot,
        currentCoursId: current?.coursId,
      ),
    );
    if (!context.mounted || choice == null) return;
    await _save([CellChange(day, slot, choice.course)]);
  }

  /// Un dépôt (I9 à I11) : refusé avant tout enregistrement s'il crée un
  /// conflit (« {nom} a déjà cours en {classe} à ce créneau »).
  Future<void> apply(DraftDropOutcome outcome) async {
    switch (outcome) {
      case DropIgnored():
        return;
      case DropRefused(:final course, :final booking):
        AppSnackBar.showError(
          context,
          _l10n.classTimetableDropConflict(
            course.teacherLabel ?? '',
            booking.classroomLabel,
          ),
        );
      case DropAccepted(:final changes):
        await _save(changes);
    }
  }

  /// Enregistrer ; un échec défait le geste à l'écran (la vue est relue) et
  /// propose de le rejouer, une fois (A7).
  Future<void> _save(List<CellChange> changes) async {
    final result = await cubit.setCells(changes);
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(
        context,
        f is TimetableRefusalFailure
            ? _l10n.classTimetableRefusal(f.code)
            : _l10n.classTimetableSaveFailed,
        onRetry: f is TimetableRefusalFailure
            ? null
            : () => cubit.setCells(changes),
      ),
      (_) {},
    );
  }

  /// O5 — abandonner, après confirmation (R7).
  Future<void> abandon() async {
    final l10n = _l10n;
    final name = view.classroom.name;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.classTimetableAbandonTitle,
      message: view.header?.isPublished ?? false
          ? l10n.classTimetableAbandonBody(name)
          : l10n.classTimetableAbandonBodyNew(name),
      confirmLabel: l10n.classTimetableAbandon,
      cancelLabel: l10n.classTimetableCancel,
      isDestructive: true,
    );
    if (!context.mounted || !confirmed) return;
    _report(
      await cubit.abandonDraft(),
      success: l10n.classTimetableSnackAbandoned,
    );
  }

  /// O4 — publier (R9) : conflits, séances hors programme et cases refusées
  /// retiennent la publication.
  Future<void> publish({required bool online}) async {
    final l10n = _l10n;
    final placed = [
      for (final c in view.draft)
        if (!c.isEmpty) c,
    ];
    final ok = await EteeloFormDialog.show<bool>(
      context,
      PublishTimetableDialog(
        sessions: placed.length,
        teachers: {for (final c in placed) ?c.teacherId}.length,
        conflicts: DraftConflicts.of(view).length,
        outOfProgramme: TimetableMarks.outOfProgramme(view).length,
        rejected: TimetableMarks.rejected(view).length,
        online: online,
        pending: view.hasPending,
      ),
    );
    if (!context.mounted || ok != true) return;
    _report(await cubit.publish(), success: l10n.classTimetableSnackPublished);
  }

  void _report(Either<Failure, Unit> result, {String? success}) {
    if (!context.mounted) return;
    result.fold(
      (f) => AppSnackBar.showError(
        context,
        f is TimetableRefusalFailure
            ? _l10n.classTimetableRefusal(f.code)
            : _l10n.classTimetableSaveFailed,
      ),
      (_) {
        if (success != null) AppSnackBar.showSuccess(context, success);
      },
    );
  }
}
