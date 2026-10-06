import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne méta d'une rangée : séances · objectifs atteints/total · blocs de
/// contenu · évaluations · notes (les notes seulement s'il y en a).
class ChapitreRowMeta extends StatelessWidget {
  final ProgrammeChapitre row;

  const ChapitreRowMeta({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chapitre = row.chapitre;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _Meta(
          Icons.schedule_rounded,
          l10n.chapitreRowSeances(chapitre.seances),
        ),
        _Meta(
          Icons.flag_outlined,
          l10n.chapitreRowObjectifs(
            chapitre.objectifsAtteints,
            chapitre.objectifs.length,
          ),
        ),
        _Meta(
          Icons.notes_rounded,
          l10n.chapitreRowBlocs(chapitre.blocs.length),
        ),
        _Meta(
          Icons.assignment_outlined,
          l10n.chapitreRowEvaluations(row.evaluationsCount),
        ),
        if (row.notesCount > 0)
          _Meta(
            Icons.sticky_note_2_outlined,
            l10n.chapitreRowNotes(row.notesCount),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Meta(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodySmall.copyWith(color: AppColors.textMuted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: ProgrammeLayout.metaIcon, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
