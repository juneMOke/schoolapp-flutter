import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Hamburger de la barre supérieure (compact) : bouton 40×40 aligné sur les
/// boutons d'action, marge gauche = padding compact de la barre (16), marge
/// droite 2 avant le titre. Ouvre le tiroir de navigation.
class TopBarLeadingMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBarLeadingMenuButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(
        left: HomeNavigationUiTokens.topBarCompactHorizontalPadding,
        right: HomeNavigationUiTokens.topBarLeadingMarginRight,
      ),
      child: Tooltip(
        message: l10n.homeOpenNavigationDrawerTooltip,
        child: Material(
          color: AppColors.textOnDark.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              HomeNavigationUiTokens.topBarActionRadius,
            ),
            side: BorderSide(
              color: AppColors.textOnDark.withValues(alpha: 0.14),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(
              HomeNavigationUiTokens.topBarActionRadius,
            ),
            onTap: onPressed,
            child: const SizedBox(
              width: HomeNavigationUiTokens.topBarActionSize,
              height: HomeNavigationUiTokens.topBarActionSize,
              child: Center(
                child: Icon(
                  Icons.menu_rounded,
                  color: AppColors.textOnDark,
                  size: HomeNavigationUiTokens.topBarActionIconSize + 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
