import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_page_section.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La page d'un registre du jour, en deux sections sur un fin fond
/// ([EteeloPageSection]), pour le Pointage comme pour l'appel :
///
/// 1. **Journée** — le bandeau du jour et ses bandeaux d'état (validé, mois
///    clos, refus d'envoi) ;
/// 2. **Registre** — les filtres, la barre de résultats, puis la table ou
///    les cartes ; ou, sans personne à pointer, l'état vide.
class PresenceRegisterSections extends StatelessWidget {
  final Widget banner;

  /// Les bandeaux d'état du jour, déjà espacés entre eux.
  final List<Widget> dayNotices;

  /// Personne à pointer ce jour-là : remplace filtres et résultats.
  final Widget? empty;
  final Widget filters;
  final Widget resultsBar;
  final Widget results;

  const PresenceRegisterSections({
    super.key,
    required this.banner,
    required this.dayNotices,
    required this.filters,
    required this.resultsBar,
    required this.results,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    final empty = this.empty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloPageSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              banner,
              if (dayNotices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ...dayNotices,
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        EteeloPageSection(
          child:
              empty ??
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  filters,
                  const SizedBox(height: AppSpacing.md),
                  resultsBar,
                  const SizedBox(height: AppSpacing.md),
                  results,
                ],
              ),
        ),
      ],
    );
  }
}
