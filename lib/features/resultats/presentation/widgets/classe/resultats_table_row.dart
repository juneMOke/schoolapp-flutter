import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultat_pct_cell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Géométrie partagée entre l'en-tête et les lignes (colonnes alignées).
const double kResultatsRankColWidth = 34;
const int kResultatsEleveFlex = 5;
const int kResultatsPeriodFlex = 3;
const int kResultatsMoyenneFlex = 4;
const double kResultatsChevronColWidth = 26;

/// Une ligne élève de la table (spec §4). Non classé → cellules « — », badge
/// « Non classé », ligne **non cliquable** (pas de chevron). Classé → chevron +
/// [onTap] vers la vue focus. Rang top 3 en or doux.
class ResultatsTableRow extends StatelessWidget {
  final ResultatEleveLigne ligne;
  final double seuil;
  final String classroomLabel;
  final int sousPeriodeCount;
  final VoidCallback? onTap;

  const ResultatsTableRow({
    super.key,
    required this.ligne,
    required this.seuil,
    required this.classroomLabel,
    required this.sousPeriodeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = !ligne.nonClasse && onTap != null;

    return Semantics(
      button: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: kResultatsRankColWidth,
                  child: _RankBadge(rang: ligne.rang),
                ),
                Expanded(flex: kResultatsEleveFlex, child: _eleveCell(l10n)),
                for (var i = 0; i < sousPeriodeCount; i++)
                  Expanded(
                    flex: kResultatsPeriodFlex,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ResultatPctCell(
                        pourcentage: _pourcentageAt(i),
                        seuil: seuil,
                      ),
                    ),
                  ),
                Expanded(
                  flex: kResultatsMoyenneFlex,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ligne.nonClasse
                        ? _NonClasseBadge(label: l10n.resultatsNonClasseBadge)
                        : ResultatPctCell(
                            pourcentage: ligne.moyenneGroupe,
                            seuil: seuil,
                            showBar: true,
                          ),
                  ),
                ),
                SizedBox(
                  width: kResultatsChevronColWidth,
                  child: enabled
                      ? const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.borderStrong,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _pourcentageAt(int index) {
    if (index < 0 || index >= ligne.pourcentages.length) {
      return null;
    }
    return ligne.pourcentages[index].pourcentage;
  }

  Widget _eleveCell(AppLocalizations l10n) {
    final subtitle = [
      resultatsGenderLabel(l10n, ligne.genre),
      classroomLabel,
    ].where((p) => p.trim().isNotEmpty).join(' · ');

    return Row(
      children: [
        StudentAvatar(
          firstName: ligne.prenom,
          lastName: ligne.nom,
          studentId: ligne.studentId,
          size: AvatarSize.md,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resultatsShortName(ligne.prenom, ligne.nom),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int? rang;

  const _RankBadge({required this.rang});

  @override
  Widget build(BuildContext context) {
    final rang = this.rang;
    if (rang == null) {
      return Text(
        AppLocalizations.of(context)!.resultatsDash,
        style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
      );
    }
    final isTop = rang <= 3;
    return Text(
      '$rang',
      style: AppTypography.labelMedium.copyWith(
        color: isTop ? AppColors.orDoux : AppColors.textMuted,
        fontWeight: isTop ? FontWeight.w700 : FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _NonClasseBadge extends StatelessWidget {
  final String label;

  const _NonClasseBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
