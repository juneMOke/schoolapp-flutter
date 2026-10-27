import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La fiche d'un agent en une seule feuille, lue de haut en bas comme un
/// document : la tête (l'agent et son profil), la portée, les taux, puis le
/// corps — calendrier et incidents, ou la table de l'année.
///
/// Un seul cadre porte bord et coins ; des filets séparent les bandes, et le
/// corps repose sur la zébrure des tables pour que ses cartes blanches s'y
/// détachent. Cinq blocs de même poids sur le fond de page se lisaient comme
/// des pièces séparées.
class HrPresenceFicheSheet extends StatelessWidget {
  /// La tête, posée bord à bord (`HrPresenceProfileCard(embedded: true)`).
  final Widget header;

  /// La portée et le choix de l'agent, nus (`HrPresenceScopeBar(framed:
  /// false)`).
  final Widget scope;
  final Widget kpis;
  final Widget body;

  const HrPresenceFicheSheet({
    super.key,
    required this.header,
    required this.scope,
    required this.kpis,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    const rule = Divider(
      height: AppDimensions.tileBorderWidth,
      thickness: AppDimensions.tileBorderWidth,
      color: AppColors.border,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            rule,
            Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: scope),
            rule,
            Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: kpis),
            rule,
            ColoredBox(
              color: ListingTones.table.zebra,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
