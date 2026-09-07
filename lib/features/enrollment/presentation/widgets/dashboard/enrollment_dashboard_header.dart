import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête du tableau de bord : où l'on est, ce qu'on regarde, à quelle date.
///
/// **Il reste visible dans les quatre états.** C'est le seul repère qui ne
/// dépend d'aucune donnée : même en erreur, l'écran continue de dire quel écran
/// il est. Le bandeau d'effectif et les onglets, eux, n'apparaissent qu'une
/// fois les données là — un total servi depuis un cache pendant qu'un appel
/// échoue serait un mensonge.
class EnrollmentDashboardHeader extends StatelessWidget {
  /// Année scolaire du contexte serveur. `null` tant que rien n'est chargé, ou
  /// quand la lecture a échoué : le sous-titre se replie alors sur sa moitié
  /// qui reste vraie.
  final String? schoolYear;

  /// Date de génération des chiffres, telle que le serveur l'a datée. `null`
  /// dans les mêmes cas.
  final DateTime? generatedAt;

  const EnrollmentDashboardHeader({
    super.key,
    this.schoolYear,
    this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = _subtitle(context, l10n);

    return Semantics(
      container: true,
      header: true,
      label:
          '${l10n.enrollmentDashboardOvertitle}. '
          '${l10n.enrollmentDashboardTitle}. $subtitle',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enrollmentDashboardOvertitle.toUpperCase(),
              style: AppTextStyles.badge.copyWith(
                color: AppColors.bleuArdoise,
                letterSpacing:
                    AppDimensions.enrollmentDashboardOvertitleLetterSpacing,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              l10n.enrollmentDashboardTitle,
              style: AppTextStyles.totalAmountLora.copyWith(
                color: AppColors.bleuArdoise,
                fontSize: AppDimensions.enrollmentStatsHeaderTitleFontSize,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// « Année scolaire 2026-2027 · au 5 septembre 2026 · … »
  ///
  /// Sans année ni date — au chargement, ou après un échec — le sous-titre
  /// tombe sur sa seule moitié encore vraie : ce que l'écran montre. Inventer
  /// une année ou dater d'aujourd'hui des chiffres qu'on n'a pas serait pire
  /// que de se taire.
  String _subtitle(BuildContext context, AppLocalizations l10n) {
    final year = schoolYear;
    final at = generatedAt;
    if (year == null || at == null) {
      return l10n.enrollmentDashboardSubtitleNoYear;
    }
    return l10n.enrollmentDashboardSubtitle(
      year,
      MaterialLocalizations.of(context).formatFullDate(at),
    );
  }
}
