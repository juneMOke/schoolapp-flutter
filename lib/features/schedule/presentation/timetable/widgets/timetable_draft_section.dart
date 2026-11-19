import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/copy_action.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_drop.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/draft_gestures.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_course_reserve.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le brouillon d'une classe (EDT §4.1, colonne Brouillon) : les avis, l'aide
/// et les actions, la réserve, puis la grille éditable. On place en
/// **touchant un créneau** (I8) à toutes les largeurs ; à partir de 976 dp
/// reçus, on glisse aussi (R14) et la réserve passe à côté de la grille. La
/// vue Semaine est imposée (R12) ; le brouillon est la semaine type, sans
/// dates ni bandeaux (R17).
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
        final grid = ScheduleWeekGrid(
          timetable: ClassWeekBuilder.build(view, view.draft),
          palette: ScheduleClassPalette.byCourse(
            ClassWeekBuilder.courseVisuals(view),
          ),
          today: null,
          keepSaturday: true,
          marks: ScheduleGridMarks(
            alerts: TimetableMarks.draftAlerts(view, l10n),
          ),
          drag: drag,
          onTapSlot: editable
              ? (day, slot) => unawaited(gestures.openSlot(day, slot))
              : null,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!online) EteeloNotice.warning(l10n.classTimetableOfflineDraft),
            if (!view.othersKnown)
              EteeloNotice.warning(l10n.classTimetablePartial),
            _Actions(
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

/// La barre d'actions du brouillon (EDT §4.6 C) : l'aide, Abandonner,
/// Copier, Publier ; sous 600 dp, une seule ligne — Copier et Abandonner en
/// icônes de 48 dp, Publier prend le reste, l'aide passe dessous (A10).
class _Actions extends StatelessWidget {
  final ClassTimetableView view;
  final ClassTimetableCubit cubit;
  final bool online;
  final bool busy;
  final bool narrow;
  final String help;
  final DraftGestures gestures;

  const _Actions({
    required this.view,
    required this.cubit,
    required this.online,
    required this.busy,
    required this.narrow,
    required this.help,
    required this.gestures,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = view.othersKnown && !busy
        ? () => unawaited(copyTimetable(context, cubit))
        : null;
    final abandon = busy ? null : () => unawaited(gestures.abandon());
    // Hors ligne, rien à placer ou un geste en cours : Publier attend
    // (refus.vide, R9).
    final publish = busy || !online || view.draft.every((c) => c.isEmpty)
        ? null
        : () => unawaited(gestures.publish(online: online));
    final helpText = Text(help, style: AppTypography.bodySmall);
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton.outlined(
                tooltip: l10n.classTimetableCopyFrom,
                onPressed: copy,
                icon: const Icon(Icons.copy_all_outlined),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                tooltip: l10n.classTimetableAbandon,
                onPressed: abandon,
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: l10n.classTimetablePublish,
                  icon: Icons.publish_outlined,
                  onPressed: publish,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          helpText,
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        helpText,
        SecondaryButton(
          label: l10n.classTimetableAbandon,
          icon: Icons.delete_outline,
          fullWidth: false,
          onPressed: abandon,
        ),
        SecondaryButton(
          label: l10n.classTimetableCopy,
          icon: Icons.copy_all_outlined,
          fullWidth: false,
          onPressed: copy,
        ),
        PrimaryButton(
          label: l10n.classTimetablePublish,
          icon: Icons.publish_outlined,
          fullWidth: false,
          onPressed: publish,
        ),
      ],
    );
  }
}
