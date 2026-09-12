import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La barre d'une page de sous-menu ouverte HORS de la coquille.
///
/// Les pages de sous-menu vivent dans la coquille de l'accueil, qui les habille
/// de sa barre latérale et de sa TopBar. Leur route, elle, les construit
/// SEULES : poussées par `push`, elles s'affichaient nues — rien pour dire où
/// l'on est, ni pour revenir. Cette barre est la barre sombre des écrans
/// poussés ([ModuleTopBar]) : sur-titre du module, titre de l'écran, et une
/// flèche qui DÉPILE, pour retrouver l'écran d'où l'on vient tel qu'on l'a
/// quitté.
///
/// Sans rien à dépiler — un lien profond —, la flèche rejoint
/// [shellSubMenuId] DANS la coquille.
class OffShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String eyebrow;
  final String title;
  final String backTooltip;

  /// Le sous-menu que la flèche rejoint quand il n'y a rien à dépiler.
  final String shellSubMenuId;

  const OffShellTopBar({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.backTooltip,
    required this.shellSubMenuId,
  });

  @override
  Size get preferredSize => ModuleTopBar.barSize;

  @override
  Widget build(BuildContext context) => ModuleTopBar(
    eyebrow: eyebrow,
    title: title,
    backTooltip: backTooltip,
    onBack: () => _leave(context),
  );

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    // `goNamed` vers l'accueil serait inerte si l'accueil était déjà SOUS la
    // pile. Il n'y est pas : rien ne se dépile.
    context.goNamed(
      AppRoutesNames.home,
      queryParameters: {'subMenuId': shellSubMenuId},
    );
  }
}
