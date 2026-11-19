import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/copy_action.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_conflicts.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/publish_timetable_dialog.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/slot_options_sheet.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le brouillon d'une classe (EDT §4.1, colonne Brouillon) : l'aide et les
/// actions, les avis (hors ligne, contrôle indisponible), la réserve, puis la
/// grille éditable — on place en **touchant un créneau** (I8), à toutes les
/// largeurs. La vue Semaine est imposée (R12).
class TimetableDraftSection extends StatelessWidget {
  final ClassTimetableView view;
  final ClassTimetableCubit cubit;
  final bool online;

  const TimetableDraftSection({
    super.key,
    required this.view,
    required this.cubit,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final conflicts = DraftConflicts.of(view);
    final week = ClassWeekBuilder.build(view, view.draft);
    final volumes = PlacedHours.volumes(
      plannedByCours: {
        for (final c in view.programme) c.coursId: c.weeklyHours,
      },
      placedCoursIds: [for (final c in view.draft) c.coursId],
    );
    final toPlace = volumes.where((v) => (v.remaining ?? 0) > 0).length;
    final (placed, planned) = PlacedHours.totals(volumes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!online) EteeloNotice.warning(l10n.classTimetableOfflineDraft),
        if (!view.othersKnown) EteeloNotice.warning(l10n.classTimetablePartial),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.classTimetableHelpDraft, style: AppTypography.bodySmall),
            SecondaryButton(
              label: l10n.classTimetableCopy,
              icon: Icons.copy_all_outlined,
              fullWidth: false,
              onPressed: view.othersKnown
                  ? () => unawaited(copyTimetable(context, cubit))
                  : null,
            ),
            SecondaryButton(
              label: l10n.classTimetableAbandon,
              icon: Icons.delete_outline,
              fullWidth: false,
              onPressed: () => unawaited(_abandon(context)),
            ),
            PrimaryButton(
              label: l10n.classTimetablePublish,
              icon: Icons.publish_outlined,
              fullWidth: false,
              onPressed: () => unawaited(_publish(context, conflicts.length)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        EteeloPanelCard(
          title: l10n.classTimetableReserveTitle,
          child: Text(
            planned == null
                ? l10n.classTimetableReserveCount(toPlace)
                : '${l10n.classTimetableReserveCount(toPlace)} · $placed/$planned h',
            style: AppTypography.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ScheduleWeekGrid(
          timetable: week,
          palette: ScheduleClassPalette.byCourse(
            ClassWeekBuilder.courseVisuals(view),
          ),
          today: null,
          keepSaturday: true,
          conflictSessionIds: conflicts.keys.toSet(),
          onTapSlot: view.othersKnown
              ? (day, slot) => unawaited(_openSlot(context, day, slot))
              : null,
        ),
      ],
    );
  }

  Future<void> _openSlot(
    BuildContext context,
    Weekday day,
    TimeSlot slot,
  ) async {
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
    final result = await cubit.setCells([CellChange(day, slot, choice.course)]);
    if (!context.mounted) return;
    _report(context, result);
  }

  Future<void> _abandon(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
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
    final result = await cubit.abandonDraft();
    if (!context.mounted) return;
    _report(context, result, success: l10n.classTimetableSnackAbandoned);
  }

  Future<void> _publish(BuildContext context, int conflicts) async {
    final l10n = AppLocalizations.of(context)!;
    final placed = [
      for (final c in view.draft)
        if (!c.isEmpty) c,
    ];
    final ok = await EteeloFormDialog.show<bool>(
      context,
      PublishTimetableDialog(
        sessions: placed.length,
        teachers: {for (final c in placed) ?c.teacherId}.length,
        conflicts: conflicts,
        online: online,
        pending: view.hasPending,
      ),
    );
    if (!context.mounted || ok != true) return;
    final result = await cubit.publish();
    if (!context.mounted) return;
    _report(context, result, success: l10n.classTimetableSnackPublished);
  }

  static void _report(
    BuildContext context,
    Either<Failure, Unit> result, {
    String? success,
  }) {
    final l10n = AppLocalizations.of(context)!;
    result.fold(
      (f) => AppSnackBar.showError(
        context,
        f is TimetableRefusalFailure
            ? l10n.classTimetableRefusal(f.code)
            : l10n.classTimetableSaveFailed,
      ),
      (_) {
        if (success != null) AppSnackBar.showSuccess(context, success);
      },
    );
  }
}
