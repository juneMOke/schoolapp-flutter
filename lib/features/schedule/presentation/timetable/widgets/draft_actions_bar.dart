import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/copy_action.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/draft_gestures.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'actions du brouillon (EDT §4.6 C) : l'aide, Abandonner,
/// Copier, Publier ; sous 600 dp, une seule ligne — Copier et Abandonner en
/// icônes de 48 dp, Publier prend le reste, l'aide passe dessous (A10).
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
