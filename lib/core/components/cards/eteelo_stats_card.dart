import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Chrome de section d'un tableau de bord : carte surélevée, titre, contenu.
///
/// Le dépôt en comptait déjà trois quasi identiques — une par tableau de bord
/// (`EnrollmentStatsChartCard`, `FinanceStatsChartCard`, `AttendanceOverviewCard`).
/// Celle-ci est la version de socle, reprise de la meilleure des trois (celle
/// des présences : bordure, ombre douce, indice optionnel), augmentée des deux
/// besoins que la refonte du tableau de bord des inscriptions fait apparaître :
/// un **sous-titre** qui dit ce que la carte montre, et une rangée d'**actions**
/// (exports) posée dans l'en-tête.
///
/// Les trois cartes existantes ne sont PAS migrées ici : leur convergence est
/// un chantier à part, à mener avec les tests de chaque écran sous la main.
class EteeloStatsCard extends StatelessWidget {
  /// Ce que la carte montre, en une phrase nominale.
  final String title;

  /// Précision sous le titre — « Où sont allés les élèves inscrits ». Sert à
  /// lever l'ambiguïté d'un titre court, pas à commenter le graphique.
  final String? subtitle;

  /// Indice discret poussé à droite du titre (ex. « 7 niveaux concernés »).
  final String? hint;

  /// Glyphe de tête, posé dans une pastille teintée à gauche du titre.
  ///
  /// ⚠️ **Écart assumé à la spec** : `.k-ct` n'a pas de slot d'icône, et la
  /// carte n'en exposait pas. Le porteur produit en demande une sur les cartes
  /// du tableau de bord des inscriptions ; la modification doit remonter dans
  /// le design system.
  ///
  /// Purement décoratif : le titre reste la seule source d'information, et
  /// l'icône est masquée aux lecteurs d'écran.
  final IconData? icon;

  /// Teinte du glyphe. La pastille en reprend une version diluée.
  final Color iconColor;

  /// Actions de l'en-tête — typiquement les exports. Vide par défaut : une
  /// carte sans export ne réserve aucune place pour des boutons absents.
  ///
  /// L'appelant les retire lui-même quand il n'y a rien à exporter ; la carte
  /// ne devine pas.
  final List<Widget> actions;

  final Widget child;

  const EteeloStatsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.hint,
    this.icon,
    this.iconColor = AppColors.bleuArdoise,
    this.actions = const [],
    required this.child,
  });

  /// Dilution de [iconColor] pour le fond de la pastille — même parti que la
  /// carte KPI, dont les pastilles voisinent dans la même grille.
  static const double iconBadgeTintAlpha = 0.12;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        // Élévation douce, cohérente avec EteeloKpiCard : les panneaux ne
        // paraissent pas plats face aux cartes KPI ombrées de la même grille.
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: title,
            subtitle: subtitle,
            hint: hint,
            icon: icon,
            iconColor: iconColor,
            actions: actions,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          child,
        ],
      ),
    );
  }
}

/// Titre, sous-titre, indice et actions.
///
/// Le titre et les actions s'enroulent l'un sous l'autre quand la carte est
/// trop étroite : sur un export à deux boutons de 44 dp, une rangée rigide
/// écraserait le titre jusqu'à l'ellipse dès la tablette en portrait.
class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? hint;
  final IconData? icon;
  final Color iconColor;
  final List<Widget> actions;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            subtitle!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );

    // La pastille est décorative : le titre dit déjà tout, et la relire
    // n'ajouterait qu'un « icône » sans objet dans le flux du lecteur d'écran.
    final heading = icon == null
        ? texts
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingXS),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(
                      alpha: EteeloStatsCard.iconBadgeTintAlpha,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.statsCardIconBadgeRadius,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: AppDimensions.statsCardIconSize,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Flexible(child: texts),
            ],
          );

    final trailing = <Widget>[
      if (hint != null)
        Text(
          hint!,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ...actions,
    ];

    if (trailing.isEmpty) {
      return SizedBox(width: double.infinity, child: heading);
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      children: [
        heading,
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingXS,
          children: trailing,
        ),
      ],
    );
  }
}
