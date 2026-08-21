import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/search/search_hint_pill.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Par quoi l'utilisateur retrouve un élève.
///
/// Les deux modes s'**excluent quant au critère qui ouvre la recherche** :
/// [level] l'ouvre sur une classe, [identity] sur un élève, et les critères de
/// l'un ne partent jamais avec l'autre. [level] vient en premier — c'est
/// l'entrée la plus courante, l'identité n'est utile que quand on cherche
/// quelqu'un de précis.
///
/// Le mode [level] porte **en plus** un affinage par nom facultatif
/// (`SearchRefineNameField`) : il n'ouvre pas la recherche, il restreint la
/// classe déjà ouverte. Ce n'est pas une entorse à l'exclusivité — sans lui,
/// retrouver quelqu'un dans une classe de soixante obligerait à connaître ses
/// trois noms.
enum SearchMode { level, identity }

/// Bascule de mode d'une carte de recherche : annonce, onglets, aide du mode
/// actif.
///
/// Trois choses rendent la bascule visible plutôt que devinable : elle est
/// **annoncée** (« Rechercher par »), elle occupe **toute la largeur** avec une
/// icône par mode, et l'aide du mode actif **nomme l'autre mode** — c'est la
/// porte de sortie de quelqu'un entré par la mauvaise.
class SearchModeSwitch extends StatelessWidget {
  final SearchMode selected;
  final ValueChanged<SearchMode> onChanged;

  /// Faux pendant qu'une recherche est en vol : basculer alors changerait les
  /// champs sous l'utilisateur pendant que la requête en cours continue, et
  /// repeuplerait la liste avec le résultat d'un mode qu'il vient de quitter.
  final bool enabled;

  const SearchModeSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLevel = selected == SearchMode.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchModeSwitchLabel.toUpperCase(),
          style: AppTextStyles.badge.copyWith(
            color: AppColors.terreCuite,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // `expand` : sur une tablette en portrait comme dans une modale, deux
        // onglets à largeur intrinsèque débordent de la carte.
        SegmentedTabFilter<SearchMode>(
          selected: selected,
          onSelected: onChanged,
          semanticsLabel: l10n.searchModeSemantics,
          expand: true,
          enabled: enabled,
          options: [
            SegmentedTabOption<SearchMode>(
              label: l10n.searchModeByClass,
              value: SearchMode.level,
              icon: Icons.grid_view_rounded,
            ),
            SegmentedTabOption<SearchMode>(
              label: l10n.searchModeByIdentity,
              value: SearchMode.identity,
              icon: Icons.person_search_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SearchHintPill(
          icon: isLevel
              ? Icons.grid_view_rounded
              : Icons.person_search_outlined,
          text: isLevel
              ? l10n.searchModeClassHint
              : l10n.searchModeIdentityHint,
        ),
      ],
    );
  }
}
