import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart' as tokens;
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Menu du compte, à l'extrémité de la barre supérieure.
///
/// « Paramètres » mène aux réglages de l'école. C'est le troisième chemin vers
/// le même écran, avec la barre latérale et la grille d'accueil — délibérément,
/// parce que c'est là qu'on le cherche d'instinct. Il navigue **dans la
/// coquille**, en pilotant la même [NavigationBloc] que les deux autres : sans
/// cela, le fil d'Ariane et la barre latérale annonceraient encore l'écran
/// précédent.
///
/// L'entrée disparaît sans `school.provisioning.write` — la même exigence que
/// le sous-menu, lue à la même source. La montrer grisée n'apprendrait rien à
/// qui ne peut pas la franchir ; la montrer active enverrait sur un écran que
/// la garde de route refuse.
class TopBarProfileMenuButton extends StatelessWidget {
  const TopBarProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canConfigure = context.select<AuthBloc, bool>(
      (bloc) => canAccessSubMenu(
        MenuConstants.configurationSchoolId,
        bloc.state.permissions,
      ),
    );

    return PopupMenuButton<String>(
      tooltip: l10n.homeUserMenuTooltip,
      onSelected: (value) {
        switch (value) {
          case 'logout':
            context.read<AuthBloc>().add(const AuthLogoutRequested());
            break;
          case 'settings':
            context.read<NavigationBloc>().add(
              SubMenuItemSelected(
                menuId: MenuConstants.configurationMenuId,
                subMenuId: MenuConstants.configurationSchoolId,
                title: l10n.subMenuConfigurationSchool,
              ),
            );
            break;
          case 'profile':
            // TODO: Handle profile action
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 8),
                Text(l10n.profile),
              ],
            ),
          ),
          if (canConfigure)
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded),
                  const SizedBox(width: 8),
                  Text(l10n.settings),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, color: AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  l10n.logout,
                  style: AppTextStyles.body.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        width: HomeNavigationUiTokens.topBarActionSize - 4,
        height: HomeNavigationUiTokens.topBarActionSize - 4,
        decoration: BoxDecoration(
          color: tokens.AppColors.textOnDark.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(
            HomeNavigationUiTokens.topBarActionRadius,
          ),
          border: Border.all(
            color: tokens.AppColors.textOnDark.withValues(alpha: 0.18),
          ),
        ),
        child: const Icon(
          Icons.person,
          color: tokens.AppColors.textOnDark,
          size: 20,
        ),
      ),
    );
  }
}
