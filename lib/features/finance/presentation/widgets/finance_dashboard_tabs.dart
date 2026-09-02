import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux moitiés du pilotage financier.
///
/// Le recouvrement est un **état** — ce qu'il reste à encaisser sur l'année ;
/// la caisse est un **flux** — ce qui est entré dans le tiroir. Les deux ont
/// vécu sur un même écran, sous un sélecteur de période commun : à la semaine,
/// les échéances tombant en fin de mois, l'attendu valait zéro et l'écran
/// annonçait « 0 attendu » un jour de guichet chargé.
enum FinanceDashboardTab { recovery, till }

/// La bascule entre les deux onglets, en cartes.
///
/// ## Pourquoi pas le segmenté du socle
///
/// [SegmentedTabFilter] sert déjà, sur cet écran même, à choisir la fenêtre de
/// la caisse. Deux segmentés empilés se liraient comme deux filtres de même
/// rang, alors que l'un change d'écran et l'autre change de période.
///
/// ## Pourquoi le descriptif n'est pas décoratif
///
/// « Recouvrement » et « Caisse » nomment deux chiffres qu'on croit volontiers
/// interchangeables. La ligne dessous dit lequel on regarde — « ce qu'il reste
/// à encaisser » contre « ce qui est entré dans le tiroir » — et c'est ce qui
/// évite de comparer un attendu à un encaissé.
///
/// Anatomie reprise du dossier élève (`DisciplinaryDossierTabs`) : médaillon
/// accentué, libellé, descriptif, carte surélevée sur l'onglet actif. Le
/// composant reste local à la finance tant qu'il n'a qu'un appelant ; une
/// troisième surface justifierait de le promouvoir au socle.
class FinanceDashboardTabs extends StatelessWidget {
  final FinanceDashboardTab selected;
  final ValueChanged<FinanceDashboardTab> onSelected;

  const FinanceDashboardTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.financeDashboardTabsA11yLabel,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.dossierTabsPadding),
        child: Row(
          children: [
            Expanded(
              child: _FinanceTab(
                active: selected == FinanceDashboardTab.recovery,
                accent: AppColors.bleuArdoise,
                accentDark: AppColors.bleuProfond,
                accentSoft: AppColors.bleuArdoiseSoft,
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.financeDashboardTabRecoveryLabel,
                description: l10n.financeDashboardTabRecoveryDescription,
                onTap: () => onSelected(FinanceDashboardTab.recovery),
              ),
            ),
            const SizedBox(width: AppDimensions.dossierTabsPadding),
            Expanded(
              child: _FinanceTab(
                active: selected == FinanceDashboardTab.till,
                accent: AppColors.terreCuite,
                accentDark: AppColors.terreCuiteDark,
                accentSoft: AppColors.terreCuiteSoft,
                icon: Icons.point_of_sale_outlined,
                label: l10n.financeDashboardTabTillLabel,
                description: l10n.financeDashboardTabTillDescription,
                onTap: () => onSelected(FinanceDashboardTab.till),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceTab extends StatelessWidget {
  final bool active;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _FinanceTab({
    required this.active,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '$label — $description',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.dossierTabRadius),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.outCurve,
              constraints: const BoxConstraints(
                minHeight: AppDimensions.dossierTabMinHeight,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM - 2,
                vertical: AppDimensions.spacingS + 3,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.surfaceRaised : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  AppDimensions.dossierTabRadius,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  _Medallion(
                    active: active,
                    accent: accent,
                    accentDark: accentDark,
                    accentSoft: accentSoft,
                    icon: icon,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: active
                                ? accentDark
                                : AppColors.textSecondary,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  final bool active;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final IconData icon;

  const _Medallion({
    required this.active,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      width: AppDimensions.dossierMedallionSize,
      height: AppDimensions.dossierMedallionSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? null : accentSoft,
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accentDark],
              )
            : null,
        borderRadius: BorderRadius.circular(
          AppDimensions.dossierMedallionRadius,
        ),
      ),
      child: Icon(icon, size: 19, color: active ? AppColors.surface : accent),
    );
  }
}
