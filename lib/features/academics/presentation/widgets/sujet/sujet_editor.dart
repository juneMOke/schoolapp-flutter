import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_bareme_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_cadre_fields.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_question_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Éditeur du sujet, en ligne dans la section (spec S2-S4) : le cadre, les
/// questions, « Ajouter une question » et le barème. La barre « Annuler |
/// Enregistrer le sujet » est portée par la page (seule barre collante
/// pendant l'édition).
class SujetEditor extends StatelessWidget {
  final SujetDraftController draft;

  /// Titres des chapitres de l'évaluation, pour « Reprendre les chapitres ».
  final List<String> chapitres;

  /// Une note est posée : le maximum ne s'ajuste plus.
  final bool maxLocked;

  /// Bandeau posé en tête (sujet déjà publié).
  final Widget? banner;

  const SujetEditor({
    super.key,
    required this.draft,
    required this.chapitres,
    required this.maxLocked,
    this.banner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final questions = draft.questions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (banner != null) ...[
              banner!,
              const SizedBox(height: AppSpacing.md),
            ],
            SujetCadreFields(
              dureeMinutes: draft.dureeMinutes,
              onDureeChanged: draft.setDuree,
              programme: draft.programme,
              onProgrammeChanged: draft.setProgramme,
              onReprendreChapitres: chapitres.isEmpty
                  ? null
                  : () => draft.setProgramme(chapitres),
              consignes: draft.consignes,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (i, q) in questions.indexed) ...[
              SujetQuestionCard(
                key: ValueKey<String>(q.id),
                draft: q,
                number: i + 1,
                isFirst: i == 0,
                isLast: i == questions.length - 1,
                onMove: (offset) => draft.move(q, offset),
                onDuplicate: draft.canAddQuestion
                    ? () => draft.duplicate(q)
                    : null,
                onDelete: () => draft.remove(q),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              height: AppDimensions.sujetAddQuestionHeight,
              child: OutlinedButton.icon(
                onPressed: draft.canAddQuestion ? draft.addQuestion : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  questions.isEmpty
                      ? l10n.sujetAddFirstQuestion
                      : l10n.sujetAddQuestion,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.bleuArdoise,
                  side: const BorderSide(color: AppColors.borderStrong),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.brMd,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SujetBaremeBar(
              bareme: draft.bareme,
              incompleteCount: draft.incompleteCount,
              maxLocked: maxLocked,
              onAdjustMax: draft.adjustMaxToTotal,
            ),
          ],
        );
      },
    );
  }
}
