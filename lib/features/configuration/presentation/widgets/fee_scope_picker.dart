import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Choix de l'assiette d'un frais : tous les niveaux ouverts, ou certains.
///
/// **Une bascule exclusive, pas deux blocs reliés par un « ou ».** Un frais dû
/// par tous — minerval, inscription — s'exprime alors en une ligne au lieu de
/// quinze, et c'est plus proche de ce que le directeur a en tête.
///
/// Il n'y a **jamais de sélection de classes** : un tarif porte sur un niveau,
/// deux classes d'un même niveau paient la même chose. C'est le modèle.
class FeeScopePicker extends StatelessWidget {
  final ProvisioningCatalog catalog;
  final StructureSelection selection;
  final FeeScopeInput value;
  final ValueChanged<FeeScopeInput> onChanged;

  const FeeScopePicker({
    super.key,
    required this.catalog,
    required this.selection,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Seuls les niveaux qui ouvrent au moins une classe : on ne facture pas un
    // niveau qu'on n'ouvre pas.
    final openCodes = selection.openLevelCodes(catalog);
    final all = value.scope == FeeScope.allOpenedLevels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l10n.configurationFeeScope, style: AppTypography.labelMedium),
            const Text(' *', style: TextStyle(color: AppColors.error)),
            const Spacer(),
            if (!all)
              Text(
                l10n.configurationFeeScopeCount(
                  value.levelCatalogCodes.length,
                  openCodes.length,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<FeeScope>(
          segments: [
            ButtonSegment<FeeScope>(
              value: FeeScope.allOpenedLevels,
              label: Text(l10n.configurationFeeScopeAll),
              icon: const Icon(Icons.select_all_rounded, size: 16),
            ),
            ButtonSegment<FeeScope>(
              value: FeeScope.levels,
              label: Text(l10n.configurationFeeScopeSome),
              icon: const Icon(Icons.checklist_rounded, size: 16),
            ),
          ],
          selected: {value.scope},
          showSelectedIcon: false,
          onSelectionChanged: (selected) {
            final scope = selected.first;
            onChanged(
              scope == FeeScope.allOpenedLevels
                  // Passer en « tous » ne garde AUCUNE liste : le serveur
                  // résout l'assiette depuis la structure, ce qui la garde
                  // juste même si un niveau s'ouvre après coup.
                  ? const FeeScopeInput.allOpenedLevels()
                  : FeeScopeInput(
                      scope: FeeScope.levels,
                      levelCatalogCodes: value.levelCatalogCodes,
                    ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (all)
          Text(
            l10n.configurationFeeScopeAllHint(openCodes.length),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          )
        else
          for (final cycle in catalog.cycles)
            _CycleLevels(
              cycle: cycle,
              selection: selection,
              picked: value.levelCatalogCodes,
              onToggle: _toggle,
              onWholeCycle: _toggleCycle,
            ),
      ],
    );
  }

  void _toggle(String levelCode) {
    final picked = [...value.levelCatalogCodes];
    picked.contains(levelCode)
        ? picked.remove(levelCode)
        : picked.add(levelCode);
    onChanged(FeeScopeInput(scope: FeeScope.levels, levelCatalogCodes: picked));
  }

  void _toggleCycle(CatalogCycle cycle) {
    final openCodes = [
      for (final level in cycle.levels)
        if (selection.isLevelOpen(level)) level.code,
    ];
    final picked = [...value.levelCatalogCodes];
    final allPicked = openCodes.every(picked.contains);

    if (allPicked) {
      picked.removeWhere(openCodes.contains);
    } else {
      for (final code in openCodes) {
        if (!picked.contains(code)) picked.add(code);
      }
    }
    onChanged(FeeScopeInput(scope: FeeScope.levels, levelCatalogCodes: picked));
  }
}

class _CycleLevels extends StatelessWidget {
  final CatalogCycle cycle;
  final StructureSelection selection;
  final List<String> picked;
  final ValueChanged<String> onToggle;
  final ValueChanged<CatalogCycle> onWholeCycle;

  const _CycleLevels({
    required this.cycle,
    required this.selection,
    required this.picked,
    required this.onToggle,
    required this.onWholeCycle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final openLevels = cycle.levels.where(selection.isLevelOpen).toList();
    // Un cycle qui n'ouvre aucune classe n'a rien à facturer : l'afficher vide
    // ferait chercher pourquoi ses niveaux ne se cochent pas.
    if (openLevels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                cycle.name,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () => onWholeCycle(cycle),
                child: Text(l10n.configurationFeeScopeWholeCycle),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final level in openLevels)
                FilterChip(
                  label: Text(level.name),
                  selected: picked.contains(level.code),
                  onSelected: (_) => onToggle(level.code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
