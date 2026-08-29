import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Recherche libre + cinq puces exclusives. Les deux se **combinent** :
/// « Uniforme » + « polo » cherche dans la famille.
///
/// Aucun seuil et aucun anti-rebond : les données sont locales, filtrer dès la
/// première lettre ne coûte rien et fait gagner une frappe au guichet.
class BoutiqueSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ArticleFamily? selectedFamily;

  /// Inerte pendant le chargement du catalogue : un champ qui filtre un
  /// squelette apprend au guichet que la recherche ne marche pas.
  final bool enabled;

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ArticleFamily?> onFamilyChanged;

  const BoutiqueSearchBar({
    super.key,
    required this.controller,
    required this.selectedFamily,
    required this.enabled,
    required this.onQueryChanged,
    required this.onFamilyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 46,
          child: TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.boutiqueSearchPlaceholder,
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            // « Toutes » en premier : c'est l'état par défaut, et le premier
            // geste de qui veut sortir d'un filtre.
            _FamilyChip(
              label: l10n.boutiqueFilterAll,
              selected: selectedFamily == null,
              accent: AppColors.bleuProfond,
              enabled: enabled,
              onSelected: () => onFamilyChanged(null),
            ),
            for (final family in ArticleFamily.values)
              _FamilyChip(
                label: BoutiqueFamilyStyle.labelOf(family, l10n),
                selected: selectedFamily == family,
                accent: BoutiqueFamilyStyle.accentOf(family),
                enabled: enabled,
                // Retaper la puce active ne la désélectionne pas : les puces
                // sont EXCLUSIVES, et « Toutes » est la sortie.
                onSelected: () => onFamilyChanged(family),
              ),
          ],
        ),
      ],
    );
  }
}

class _FamilyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool enabled;
  final VoidCallback onSelected;

  const _FamilyChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: enabled ? (_) => onSelected() : null,
    selectedColor: AppColors.bleuProfond,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.textPrimary,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: BorderSide(
        color: selected ? AppColors.bleuProfond : AppColors.border,
      ),
    ),
  );
}
