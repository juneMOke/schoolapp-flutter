import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/copy_action.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/draft_gestures.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_icon_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'actions du brouillon (EDT §4.6 C) : l'aide en pastille ambre,
/// puis « Abandonner » (discret), « Copier… » (secondaire) et « Publier »
/// (principal). Sous 600 dp, une seule ligne — Copier et Abandonner en icônes
/// de 48 dp, Publier prend le reste — et l'aide passe dessous (A10).
class DraftActionsBar extends StatelessWidget {
  final ClassTimetableView view;
  final ClassTimetableCubit cubit;
  final bool online;
  final bool busy;
  final bool narrow;
  final String help;
  final DraftGestures gestures;

  const DraftActionsBar({
    super.key,
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
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TimetableIconButton(
                icon: Icons.copy_all_outlined,
                tooltip: l10n.classTimetableCopyFrom,
                onPressed: copy,
              ),
              const SizedBox(width: AppSpacing.sm),
              TimetableIconButton(
                icon: Icons.close_rounded,
                tooltip: l10n.classTimetableAbandonDraft,
                tone: AppColors.terreCuiteInk,
                onPressed: abandon,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: l10n.classTimetablePublish,
                  icon: Icons.send_outlined,
                  onPressed: publish,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.pan_tool_outlined,
                size: AppSpacing.md,
                color: AppColors.timetableHintInk,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  help,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.timetableHintInk,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DraftHelpPill(help: help),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: abandon,
              icon: const Icon(Icons.close_rounded),
              label: Text(l10n.classTimetableAbandon),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(
                  AppDimensions.minTouchTarget,
                  AppDimensions.minTouchTarget,
                ),
              ),
            ),
            SecondaryButton(
              label: l10n.classTimetableCopy,
              icon: Icons.copy_all_outlined,
              fullWidth: false,
              onPressed: copy,
            ),
            PrimaryButton(
              label: l10n.classTimetablePublish,
              icon: Icons.send_outlined,
              fullWidth: false,
              onPressed: publish,
            ),
          ],
        ),
      ],
    );
  }
}

/// L'aide du brouillon, en pastille ambre (icône main).
class DraftHelpPill extends StatelessWidget {
  final String help;

  const DraftHelpPill({super.key, required this.help});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.timetableHintSurface,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.timetableHintBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.pan_tool_outlined,
          size: AppSpacing.md,
          color: AppColors.timetableHintInk,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            help,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.timetableHintInk,
            ),
          ),
        ),
      ],
    ),
  );
}
