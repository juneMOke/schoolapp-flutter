import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/chapitre_numero_tile.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/chapitre_statut_badge.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_sync_pill.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/chapitre_row_actions.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/programme/chapitre_row_meta.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une rangée du programme (spec §3) : numéro, titre + statut, résumé, méta,
/// gestes. Toute la rangée ouvre le chapitre (tap, Entrée, Espace).
class ChapitreRow extends StatelessWidget {
  final ProgrammeChapitre row;

  /// Position dans le programme, à partir de 1.
  final int numero;
  final VoidCallback onOpen;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const ChapitreRow({
    super.key,
    required this.row,
    required this.numero,
    required this.onOpen,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chapitre = row.chapitre;
    final compact =
        MediaQuery.sizeOf(context).width < ProgrammeLayout.compactRowBelow;
    final resume = chapitre.resume?.trim() ?? '';
    return Semantics(
      button: true,
      label: l10n.chapitreActionOpen(numero, chapitre.titre),
      child: InkWell(
        onTap: onOpen,
        hoverColor: AppColors.stateHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChapitreNumeroTile(
                numero: numero,
                statut: chapitre.statut,
                size: ProgrammeLayout.rowNumber,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          chapitre.titre,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ChapitreStatutBadge(statut: chapitre.statut),
                        ProgrammeSyncPill(state: chapitre.syncState),
                      ],
                    ),
                    if (resume.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        resume,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    ChapitreRowMeta(row: row),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ProgrammeWriteGate(
                child: ChapitreRowActions(
                  onMoveUp: onMoveUp,
                  onMoveDown: onMoveDown,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  compact: compact,
                ),
              ),
              const ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
