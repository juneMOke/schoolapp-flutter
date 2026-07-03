import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/branche_resultat.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/bulletin_domaine.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/domaine_resultat.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_score_palette.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bulletin par domaine (spec §8) : les branches regroupées par domaine (arbre
/// **récursif** `DomaineResultat`), avec sous-totaux et total obtenu.
///
/// Le seuil de réussite n'étant pas porté par la vue focus, la coloration des
/// notes utilise le défaut backend [ResultatBulletinDomaine.defautSeuil] (50 %).
/// Les colonnes par période du gabarit officiel ne sont **pas** rendues ici (la
/// vue focus est agrégée) : elles restent au bulletin officiel imprimable.
class ResultatBulletinDomaine extends StatelessWidget {
  static const double defautSeuil = 50;

  final BulletinDomaine bulletin;
  final String periodeLongLabel;
  final double seuil;

  const ResultatBulletinDomaine({
    super.key,
    required this.bulletin,
    required this.periodeLongLabel,
    this.seuil = defautSeuil,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerBand(l10n),
          for (final widget in _buildNodes(l10n, bulletin.domaines, 0)) widget,
          _TotalRow(
            obtenu: bulletin.totalObtenu,
            max: bulletin.totalMax,
            pourcentage: bulletin.pourcentage,
            seuil: seuil,
          ),
        ],
      ),
    );
  }

  Widget _headerBand(AppLocalizations l10n) {
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.resultatsBulletinTitle(periodeLongLabel),
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.bleuProfond,
              ),
            ),
          ),
          Text(
            l10n.resultatsBulletinLegend,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNodes(
    AppLocalizations l10n,
    List<DomaineResultat> nodes,
    int depth,
  ) {
    final widgets = <Widget>[];
    for (final node in nodes) {
      final label = node.label;
      if (label != null && label.trim().isNotEmpty) {
        widgets.add(_DomainBand(label: label, depth: depth));
      }
      for (final branche in node.branches) {
        widgets.add(_BrancheRow(branche: branche, seuil: seuil, depth: depth));
      }
      widgets.addAll(_buildNodes(l10n, node.sousRubriques, depth + 1));
      if (node.produitSousTotal) {
        widgets.add(
          _SubtotalRow(
            label: l10n.resultatsBulletinSubtotal,
            obtenu: node.obtenu,
            max: node.max,
            pourcentage: node.pourcentage,
            seuil: seuil,
          ),
        );
      }
    }
    return widgets;
  }
}

class _DomainBand extends StatelessWidget {
  final String label;
  final int depth;

  const _DomainBand({required this.label, required this.depth});

  @override
  Widget build(BuildContext context) {
    final isTop = depth == 0;
    return Container(
      width: double.infinity,
      color: isTop ? AppColors.terreCuiteSoft : AppColors.surfaceAlt,
      padding: EdgeInsets.only(
        left: AppSpacing.md + depth * AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        isTop ? label.toUpperCase() : label,
        style: AppTypography.labelSmall.copyWith(
          color: isTop ? AppColors.terreCuite : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: isTop ? 0.5 : 0,
        ),
      ),
    );
  }
}

class _BrancheRow extends StatelessWidget {
  final BrancheResultat branche;
  final double seuil;
  final int depth;

  const _BrancheRow({
    required this.branche,
    required this.seuil,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _RowShell(
      indent: depth * AppSpacing.md,
      leading: Text(
        branche.brancheNom,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      note: resultatsNoteOverMax(l10n, branche.obtenu, branche.max),
      // « Non noté » (pourcentage null) reste neutre : ne jamais colorer en
      // rouge une branche non évaluée comme un échec (revue §quality).
      noteColor: branche.pourcentage == null
          ? AppColors.textMuted
          : ResultatsScorePalette.noteColor(branche.obtenu, branche.max, seuil),
      pourcentage: branche.pourcentage,
      seuil: seuil,
    );
  }
}

class _SubtotalRow extends StatelessWidget {
  final String label;
  final double obtenu;
  final double max;
  final double? pourcentage;
  final double seuil;

  const _SubtotalRow({
    required this.label,
    required this.obtenu,
    required this.max,
    required this.pourcentage,
    required this.seuil,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _RowShell(
      background: AppColors.surfaceAlt,
      leading: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.bleuProfond,
          fontWeight: FontWeight.w600,
        ),
      ),
      note: resultatsNoteOverMax(l10n, obtenu, max),
      noteColor: AppColors.textPrimary,
      pourcentage: pourcentage,
      seuil: seuil,
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double obtenu;
  final double max;
  final double pourcentage;
  final double seuil;

  const _TotalRow({
    required this.obtenu,
    required this.max,
    required this.pourcentage,
    required this.seuil,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.resultatsBulletinTotal,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.bleuProfond,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            resultatsNoteOverMax(l10n, obtenu, max),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PctChip(pourcentage: pourcentage, seuil: seuil, filled: true),
        ],
      ),
    );
  }
}

/// Coquille commune d'une ligne branche/sous-total : nom + note/max + pastille %.
class _RowShell extends StatelessWidget {
  final Widget leading;
  final String note;
  final Color noteColor;
  final double? pourcentage;
  final double seuil;
  final Color? background;
  final double indent;

  const _RowShell({
    required this.leading,
    required this.note,
    required this.noteColor,
    required this.pourcentage,
    required this.seuil,
    this.background,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md + indent,
        right: AppSpacing.md,
        top: AppSpacing.sm + 1,
        bottom: AppSpacing.sm + 1,
      ),
      decoration: BoxDecoration(
        color: background,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: leading),
          Text(
            note,
            style: AppTypography.bodyMedium.copyWith(
              color: noteColor,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PctChip(pourcentage: pourcentage, seuil: seuil),
        ],
      ),
    );
  }
}

class _PctChip extends StatelessWidget {
  final double? pourcentage;
  final double seuil;
  final bool filled;

  const _PctChip({
    required this.pourcentage,
    required this.seuil,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = ResultatsScorePalette.toneFor(pourcentage, seuil);
    final accent = ResultatsScorePalette.barColor(tone);

    if (filled) {
      return Container(
        constraints: const BoxConstraints(minWidth: 46),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bleuArdoise,
          borderRadius: AppRadius.brPill,
        ),
        child: Text(
          resultatsPercent(l10n, pourcentage),
          textAlign: TextAlign.center,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        resultatsPercent(l10n, pourcentage),
        textAlign: TextAlign.center,
        style: AppTypography.labelSmall.copyWith(
          color: pourcentage == null ? AppColors.textMuted : accent,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
