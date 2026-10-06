import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/chapitre_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les chapitres d'un programme, dans l'ordre de progression : une seule
/// carte sans padding, rangées séparées d'un filet.
class ProgrammeChapitresCard extends StatelessWidget {
  final List<ProgrammeChapitre> chapitres;

  /// Lu en ligne : les rangées s'ouvrent, aucun geste ne part.
  final bool readOnly;
  final void Function(Chapitre chapitre) onOpen;
  final void Function(Chapitre chapitre, int offset) onMove;
  final void Function(Chapitre chapitre)? onEdit;
  final void Function(Chapitre chapitre) onDelete;

  const ProgrammeChapitresCard({
    super.key,
    required this.chapitres,
    this.readOnly = false,
    required this.onOpen,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final last = chapitres.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              text: l10n.programmeChapitresTitle,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: '  ${l10n.programmeChapitresSubtitle}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.brLg,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  for (var i = 0; i <= last; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _row(chapitres[i], i, last),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(ProgrammeChapitre row, int index, int last) {
    final chapitre = row.chapitre;
    final edit = onEdit;
    return ChapitreRow(
      key: ValueKey<String>(chapitre.id),
      row: row,
      numero: index + 1,
      onOpen: () => onOpen(chapitre),
      onMoveUp: readOnly || index == 0 ? null : () => onMove(chapitre, -1),
      onMoveDown: readOnly || index == last ? null : () => onMove(chapitre, 1),
      onEdit: edit == null || !chapitre.editable ? null : () => edit(chapitre),
      onDelete: readOnly ? null : () => onDelete(chapitre),
    );
  }
}
