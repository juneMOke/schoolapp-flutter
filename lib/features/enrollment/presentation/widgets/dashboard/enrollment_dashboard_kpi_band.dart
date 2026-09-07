import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres clés de la fenêtre.
///
/// **Quatre, plus cinq.** La carte « Dossiers en cours » a été retirée : depuis
/// que l'effectif ne compte que les dossiers terminés, sa prémisse — « l'élève
/// est compté dans l'effectif mais son dossier n'est pas clos » — est devenue
/// fausse. Le compteur reste dans la charge utile et dans le modèle ; il n'est
/// simplement plus lu ici.
///
/// ## Deux invariants qui se lisent sur cette bande
///
/// * `first + re + pre + inProgress == total`, les quatre compteurs étant
///   disjoints. **Pas** `first + re == total` : cette égalité n'est vraie
///   qu'en production, où `pre` et `inProgress` valent zéro, et une seule
///   préinscription la casserait.
/// * `pre` n'entre jamais dans `total`. Une pré-inscription n'est pas une
///   inscription ; elle le devient à sa validation, et à cette date-là.
class EnrollmentDashboardKpiBand extends StatelessWidget {
  final EnrollmentKpis kpis;

  /// Le libellé de la fenêtre, en minuscules, pour titrer la première carte.
  final String windowLabel;

  const EnrollmentDashboardKpiBand({
    super.key,
    required this.kpis,
    required this.windowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloKpiBand(
          cards: [
            EteeloKpiCardData(
              label: l10n.enrollmentDashboardKpiEnrollments(
                windowLabel.toLowerCase(),
              ),
              value: kpis.totalEnrollments.value,
              subline: l10n.enrollmentDashboardKpiEnrollmentsSubline,
              accent: AppColors.enrollmentStatsAccent,
              accentSoft: AppColors.enrollmentStatsAccentSoft,
              icon: Icons.how_to_reg_rounded,
            ),
            EteeloKpiCardData(
              label: l10n.enrollmentDashboardKpiFirst,
              value: kpis.firstEnrollments.value,
              subline: _shareSubline(
                l10n,
                kpis.firstEnrollments,
                (percent) => l10n.enrollmentDashboardKpiFirstSubline(percent),
              ),
              accent: AppColors.enrollmentStatsFirst,
              accentSoft: AppColors.enrollmentStatsFirstSoft,
              icon: Icons.person_add_rounded,
            ),
            EteeloKpiCardData(
              label: l10n.enrollmentDashboardKpiRe,
              value: kpis.reEnrollments.value,
              subline: _shareSubline(
                l10n,
                kpis.reEnrollments,
                (percent) => l10n.enrollmentDashboardKpiReSubline(percent),
              ),
              accent: AppColors.enrollmentStatsRe,
              accentSoft: AppColors.enrollmentStatsReSoft,
              icon: Icons.refresh_rounded,
            ),
            EteeloKpiCardData(
              label: l10n.enrollmentDashboardKpiPre,
              value: kpis.preEnrollments.value,
              // Zéro n'est pas « rien à dire » : c'est « rien à traiter », et
              // ça se formule autrement qu'un pourcentage de zéro.
              subline: kpis.preEnrollments.value == 0
                  ? l10n.enrollmentDashboardKpiNoOnlineRequest
                  : l10n.enrollmentDashboardKpiPreSubline,
              accent: AppColors.enrollmentStatsPre,
              accentSoft: AppColors.enrollmentStatsPreSoft,
              icon: Icons.public_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _Note(text: l10n.enrollmentDashboardKpiNote),
      ],
    );
  }

  /// « X % des inscriptions de la période · … », ou l'absence dite en toutes
  /// lettres.
  ///
  /// Une carte à zéro afficherait sinon « 0 % des inscriptions de la période »,
  /// ce qui se lit comme un résultat quand cela veut dire qu'il n'y a rien à
  /// rapporter.
  String _shareSubline(
    AppLocalizations l10n,
    KpiValue value,
    String Function(int percent) template,
  ) {
    if (value.value == 0) return l10n.enrollmentDashboardKpiNoneOnWindow;
    return template(value.percentOfTotal ?? 0);
  }
}

/// La note sous la bande — ce qu'aucune carte ne peut dire seule.
class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: AppDimensions.detailMiniIconSize,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
