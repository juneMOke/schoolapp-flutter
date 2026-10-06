import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/common/accent_edge_card.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_statut_visual.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/chapitre_numero_tile.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/chapitre_statut_badge.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_sync_pill.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête d'un chapitre (spec §7) : liséré et numéro aux couleurs du
/// statut, titre, puces (rattachement · séances · classe · objectifs), et les
/// gestes — « Modifier » et le statut rapide, qui s'enregistre aussitôt.
class ChapitreHeaderCard extends StatelessWidget {
  final Chapitre chapitre;
  final int numero;
  final CoursDetailArgs cours;
  final List<SousPeriodeOption> sousPeriodes;
  final VoidCallback onEdit;
  final ValueChanged<ChapitreStatut> onStatut;

  const ChapitreHeaderCard({
    super.key,
    required this.chapitre,
    required this.numero,
    required this.cours,
    required this.sousPeriodes,
    required this.onEdit,
    required this.onStatut,
  });

  String? _sousPeriodeLabel(AppLocalizations l10n) {
    final option = sousPeriodes
        .where((sp) => sp.id == chapitre.sousPeriodeId)
        .firstOrNull;
    return option == null ? null : l10n.courseDetailPeriodLabel(option.ordre);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = ChapitreStatutVisual.of(chapitre.statut);
    final sousPeriode = _sousPeriodeLabel(l10n);
    final editable = !chapitre.awaitingDownload;
    return AccentEdgeCard(
      accent: visual.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChapitreNumeroTile(
                numero: numero,
                statut: chapitre.statut,
                size: ProgrammeLayout.headerMedallion,
                textStyle: AppTypography.titleLarge,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Identity(chapitre: chapitre)),
              if (editable)
                ProgrammeWriteGate(
                  child: EteeloButton.secondary(
                    label: l10n.chapitreActionEdit,
                    icon: Icons.edit_outlined,
                    onPressed: onEdit,
                    fullWidth: false,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (sousPeriode != null) EteeloChip(label: sousPeriode),
              EteeloChip(label: l10n.chapitreRowSeances(chapitre.seances)),
              EteeloChip(label: cours.classroomName),
              EteeloChip(
                label: l10n.chapitreChipObjectifs(
                  chapitre.objectifsAtteints,
                  chapitre.objectifs.length,
                ),
              ),
            ],
          ),
          if (editable)
            ProgrammeWriteGate(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _QuickStatut(
                  value: chapitre.statut,
                  onChanged: onStatut,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                l10n.chapitreAwaitingDownloadHint,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final Chapitre chapitre;

  const _Identity({required this.chapitre});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.chapitreDetailEyebrow,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            ChapitreStatutBadge(
              statut: chapitre.statut,
              size: StatusBadgeSize.small,
            ),
            ProgrammeSyncPill(state: chapitre.syncState),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            chapitre.titre,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Les trois boutons du statut rapide : actif = bord épais et fond doux.
class _QuickStatut extends StatelessWidget {
  final ChapitreStatut value;
  final ValueChanged<ChapitreStatut> onChanged;

  const _QuickStatut({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final statut in ChapitreStatut.values) _quickButton(l10n, statut),
      ],
    );
  }

  Widget _quickButton(AppLocalizations l10n, ChapitreStatut statut) {
    final visual = ChapitreStatutVisual.of(statut);
    final selected = statut == value;
    final label = ChapitreStatutVisual.label(l10n, statut);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: IconButton(
        tooltip: l10n.chapitreQuickStatut(label),
        onPressed: selected ? null : () => onChanged(statut),
        icon: Icon(visual.icon, size: ProgrammeLayout.iconMedium),
        color: visual.accent,
        disabledColor: visual.accent,
        style: IconButton.styleFrom(
          backgroundColor: selected ? visual.soft : null,
          side: BorderSide(
            color: selected ? visual.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
