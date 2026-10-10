import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_statut_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bloc « chapitre » en tête de la modale : le chapitre du programme (ou
/// hors programme), une aide selon le cas, et « Reprendre du chapitre »
/// quand un changement de chapitre n'a rien écrasé.
class JournalChapterBlock extends StatelessWidget {
  const JournalChapterBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<JournalEntryCubit, JournalEntryState>(
      buildWhen: (prev, curr) =>
          prev.chapters != curr.chapters ||
          prev.chapitreId != curr.chapitreId ||
          prev.canApplyChapter != curr.canApplyChapter ||
          prev.isBusy != curr.isBusy,
      builder: (context, state) {
        final cubit = context.read<JournalEntryCubit>();
        final help = state.chapters.isEmpty
            ? l10n.journalChapterHelpEmpty
            : state.chapitreId == null
            ? l10n.journalChapterHelpFree
            : l10n.journalChapterHelpLinked;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.journalChapterSurface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.journalChapterBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EteeloSelectInput<String?>(
                label: l10n.journalChapterLabel,
                value: state.chapitreId,
                enabled: !state.isBusy,
                items: [
                  EteeloSelectItem(value: null, label: l10n.journalChapterNone),
                  for (var i = 0; i < state.chapters.length; i++)
                    EteeloSelectItem(
                      value: state.chapters[i].id,
                      label: l10n.journalChapterOption(
                        i + 1,
                        state.chapters[i].titre,
                        ChapitreStatutVisual.label(
                          l10n,
                          state.chapters[i].statut,
                        ),
                      ),
                    ),
                ],
                onChanged: cubit.selectChapter,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                help,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.journalChapterInk,
                ),
              ),
              if (state.canApplyChapter) ...[
                const SizedBox(height: AppSpacing.sm),
                EteeloButton.secondary(
                  label: l10n.journalChapterApply,
                  icon: Icons.auto_awesome_rounded,
                  onPressed: cubit.applyChapter,
                  fullWidth: false,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
