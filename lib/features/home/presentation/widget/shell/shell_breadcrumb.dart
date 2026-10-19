import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fil d'Ariane « Accueil / Module / Écran » des écrans qui ne sont pas plein
/// cadre.
class ShellBreadcrumb extends StatelessWidget {
  final NavigationState state;

  const ShellBreadcrumb({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Lookup tolérant : un selectedMenuId qui ne correspondrait à aucun menu
    // (état incohérent) ne doit jamais faire planter le fil d'Ariane.
    final selectedMenuMatches = state.menuItems.where(
      (menu) => menu.id == state.selectedMenuId,
    );
    final selectedMenuTitle = selectedMenuMatches.isEmpty
        ? null
        : selectedMenuMatches.first.title;
    final secondary = AppTextStyles.body.copyWith(
      color: AppTheme.textSecondaryColor,
    );
    const separator = Text(
      ' / ',
      style: TextStyle(color: AppTheme.textSecondaryColor),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.home, style: secondary),
          if (selectedMenuTitle != null) ...[
            separator,
            Text(selectedMenuTitle, style: secondary),
          ],
          if (state.selectedSubMenuId != null) ...[
            separator,
            Text(
              state.currentTitle,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
