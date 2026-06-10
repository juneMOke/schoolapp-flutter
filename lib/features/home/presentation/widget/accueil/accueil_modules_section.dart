import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_module_card.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Vos modules » : en-tête éditorial + grille responsive de cartes
/// (spec Accueil §02/§03). La grille se reconfigure par largeur minimale d'item
/// (auto-fill minmax(248, 1fr)) : 1 → 2 → 4 colonnes.
class AccueilModulesSection extends StatelessWidget {
  final List<AccueilModule> modules;

  const AccueilModulesSection({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accueilModulesEyebrow.toUpperCase(),
          style: AppTextStyles.badge.copyWith(
            color: AppColors.terreCuite,
            letterSpacing: AccueilUiTokens.sectionEyebrowLetterSpacing,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AccueilUiTokens.sectionTitleGapTop),
        Semantics(
          header: true,
          child: Text(
            l10n.accueilModulesTitle,
            style: AppTextStyles.sidebarTitle.copyWith(
              color: AppColors.bleuProfond,
              fontSize: AccueilUiTokens.sectionTitleFontSize,
            ),
          ),
        ),
        const SizedBox(height: AccueilUiTokens.sectionTitleGapBottom),
        Text(
          l10n.accueilModulesIntro,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AccueilUiTokens.sectionHeaderToGridGap),
        _ModulesGrid(modules: modules),
      ],
    );
  }
}

/// Grille manuelle : on calcule le nombre de colonnes comme le ferait
/// `auto-fill minmax(248, 1fr)`, puis on dispose les cartes en rangées
/// d'égale hauteur (`IntrinsicHeight`) pour aligner les pieds de cartes.
class _ModulesGrid extends StatelessWidget {
  final List<AccueilModule> modules;

  const _ModulesGrid({required this.modules});

  int _columnCount(double width) {
    const gap = AccueilUiTokens.gridGap;
    const minItem = AccueilUiTokens.gridMinItemWidth;
    final raw = ((width + gap) / (minItem + gap)).floor();
    return raw.clamp(1, AccueilUiTokens.gridMaxColumns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        final rows = <Widget>[];

        for (var start = 0; start < modules.length; start += columns) {
          final end = (start + columns).clamp(0, modules.length);
          final rowModules = modules.sublist(start, end);
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: AccueilUiTokens.gridGap));
          }
          rows.add(_buildRow(rowModules, columns));
        }

        return Column(children: rows);
      },
    );
  }

  Widget _buildRow(List<AccueilModule> rowModules, int columns) {
    final children = <Widget>[];
    for (var i = 0; i < columns; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: AccueilUiTokens.gridGap));
      }
      // Les emplacements vides de la dernière rangée gardent la largeur des
      // cartes constante d'une rangée à l'autre.
      children.add(
        Expanded(
          child: i < rowModules.length
              ? AccueilModuleCard(module: rowModules[i])
              : const SizedBox.shrink(),
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
