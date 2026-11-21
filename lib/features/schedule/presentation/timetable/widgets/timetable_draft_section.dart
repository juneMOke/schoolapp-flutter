import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_drop.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/draft_actions_bar.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/draft_gestures.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_course_reserve.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le brouillon d'une classe (EDT §4.1, colonne Brouillon) : les avis, l'aide
/// et les actions, la réserve, puis la grille éditable. On place en
/// **touchant un créneau** (I8) à toutes les largeurs ; à partir de 976 dp
/// reçus, on glisse aussi (R14) et la réserve passe à côté de la grille. Le
/// brouillon est la semaine type, sans dates ni bandeaux (R17), et toujours
/// en vue Semaine (R12) : sous la largeur mini, la grille défile de côté,
/// heures figées et « Suite » au bord.
class TimetableDraftSection extends StatelessWidget {
  final ClassTimetableView view;
  final ClassTimetableCubit cubit;
  final bool online;

  /// Un geste est en cours : les actions attendent (I19).
  final bool busy;

  const TimetableDraftSection({
    super.key,
    required this.view,
    required this.cubit,
    required this.online,
    this.busy = false,
  });

  /// À la souris (poste, web) le glisser part tout de suite ; au doigt,
  /// après un appui long (R14).
  static bool get _pointerFirst =>
      kIsWeb ||
      const {
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }.contains(defaultTargetPlatform);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gestures = DraftGestures(context, view: view, cubit: cubit);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.sideBySideMin;
        final narrow = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        final editable = view.othersKnown && !busy;
        final drag = wide && editable
            ? ScheduleGridDrag(
                longPress: !_pointerFirst,
                canDrop: (data, day, slot) =>
                    DraftDrop.onSlot(view, data, day, slot) is! DropIgnored,
                onDrop: (data, day, slot) => unawaited(
                  gestures.apply(DraftDrop.onSlot(view, data, day, slot)),
                ),
              )
            : null;
        final reserve = TimetableCourseReserve(
          view: view,
          drag: drag,
          onDropped: (data) =>
              unawaited(gestures.apply(DraftDrop.onReserve(data))),
        );
        final week = ClassWeekBuilder.build(view, view.draft);
        final palette = ScheduleClassPalette.byCourse(
          ClassWeekBuilder.courseVisuals(view),
        );
        final marks = ScheduleGridMarks(
          alerts: TimetableMarks.draftAlerts(view, l10n),
        );
        final onTapSlot = editable
            ? (Weekday day, TimeSlot slot) =>
                  unawaited(gestures.openSlot(day, slot))
            : null;
        final grid = ScheduleWeekGrid(
          timetable: week,
          palette: palette,
          today: null,
          keepSaturday: true,
          marks: marks,
          drag: drag,
          onTapSlot: onTapSlot,
          look: ScheduleGridLook.classTimetable,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!online) EteeloNotice.warning(l10n.classTimetableOfflineDraft),
            if (!view.othersKnown)
              EteeloNotice.warning(l10n.classTimetablePartial),
            DraftActionsBar(
              view: view,
              cubit: cubit,
              online: online,
              busy: busy,
              narrow: narrow,
              help: wide
                  ? l10n.classTimetableHelpDrag
                  : l10n.classTimetableHelpDraft,
              gestures: gestures,
            ),
            const SizedBox(height: AppSpacing.md),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppDimensions.timetableReserveWidth,
                    child: reserve,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: grid),
                ],
              )
            else ...[
              reserve,
              const SizedBox(height: AppSpacing.md),
              grid,
            ],
          ],
        );
      },
    );
  }
}
