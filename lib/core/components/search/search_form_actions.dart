import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

/// Actions standard des formulaires de recherche bi-mode : « Effacer »
/// (ghost, gauche) / « Rechercher » (primaire, droite). Partagé pour garder
/// la même convention (ordre, icônes, libellés) sur tous ces formulaires.
class SearchFormActions extends StatelessWidget {
  final bool isLoading;
  final bool canSearch;
  final VoidCallback onClear;
  final VoidCallback onSearch;
  final String clearLabel;
  final String searchLabel;

  const SearchFormActions({
    super.key,
    required this.isLoading,
    required this.canSearch,
    required this.onClear,
    required this.onSearch,
    required this.clearLabel,
    required this.searchLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        EteeloButton.ghost(
          onPressed: isLoading ? null : onClear,
          icon: Icons.refresh_rounded,
          label: clearLabel,
        ),
        EteeloButton.primary(
          onPressed: canSearch ? onSearch : null,
          icon: Icons.search_rounded,
          label: searchLabel,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
