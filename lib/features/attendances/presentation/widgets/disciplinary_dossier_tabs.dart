import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre d'onglets proéminente de la fiche élève (coquille) : segmenté à deux
/// colonnes (Discipline d'abord, puis Présence). Chaque onglet porte un
/// médaillon accentué, un libellé + descriptif ; Discipline affiche un badge
/// rouge « cas ouverts ». L'onglet actif gagne une carte surélevée et un
/// médaillon en dégradé. Pilote le [TabController] partagé.
class DisciplinaryDossierTabs extends StatelessWidget {
  final TabController controller;
  final int openCasesCount;

  const DisciplinaryDossierTabs({
    super.key,
    required this.controller,
    required this.openCasesCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = controller.index;
        return Semantics(
          container: true,
          label: l10n.dossierTabsA11yLabel,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(
                AppDimensions.sectionCardRadius,
              ),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppDimensions.dossierTabsPadding),
            child: Row(
              children: [
                Expanded(
                  child: _DossierTab(
                    active: index == 0,
                    accent: AppColors.terreCuite,
                    accentDark: AppColors.terreCuiteDark,
                    accentSoft: AppColors.terreCuiteSoft,
                    icon: Icons.assignment_outlined,
                    label: l10n.dossierTabDisciplineLabel,
                    description: l10n.dossierTabDisciplineDescription,
                    badgeCount: openCasesCount,
                    onTap: () => controller.animateTo(0),
                  ),
                ),
                const SizedBox(width: AppDimensions.dossierTabsPadding),
                Expanded(
                  child: _DossierTab(
                    active: index == 1,
                    accent: AppColors.bleuArdoise,
                    accentDark: AppColors.bleuProfond,
                    accentSoft: AppColors.bleuArdoiseSoft,
                    icon: Icons.calendar_today_outlined,
                    label: l10n.dossierTabPresenceLabel,
                    description: l10n.dossierTabPresenceDescription,
                    badgeCount: 0,
                    onTap: () => controller.animateTo(1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DossierTab extends StatelessWidget {
  final bool active;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final IconData icon;
  final String label;
  final String description;
  final int badgeCount;
  final VoidCallback onTap;

  const _DossierTab({
    required this.active,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.icon,
    required this.label,
    required this.description,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
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
                            ),
                            if (badgeCount > 0) ...[
                              const SizedBox(width: AppDimensions.spacingS),
                              _Badge(count: badgeCount),
                            ],
                          ],
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

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.dossierBadgeMinSize,
        minHeight: AppDimensions.dossierBadgeMinSize,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXS),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.badge.copyWith(
          color: AppColors.surface,
          fontFeatures: AppTextStyles.tabularFigures,
        ),
      ),
    );
  }
}
