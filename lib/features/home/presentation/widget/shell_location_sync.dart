import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Tient l'adresse et l'écran de la coquille d'accord, dans les deux sens.
///
/// - **Menu → adresse** : choisir un écran (menu latéral, tuile, lien d'un
///   module à l'autre) inscrit `/home/{sousMenu}` dans l'historique — le
///   navigateur peut y revenir, F5 y ramène, le lien se partage.
/// - **Adresse → menu** : Précédent / Suivant, ou un lien ouvert, change
///   [subMenuId] — l'écran suit.
///
/// Chaque sens ne s'active que si l'autre n'est pas déjà d'accord : pas de
/// boucle, et le premier rendu n'écrit rien.
class ShellLocationSync extends StatefulWidget {
  /// Le sous-menu porté par l'adresse ; `null` pour l'Accueil.
  final String? subMenuId;
  final Widget child;

  const ShellLocationSync({
    super.key,
    required this.subMenuId,
    required this.child,
  });

  /// Sélectionne [subMenuId] dans [bloc] s'il est dans l'arborescence
  /// (filtrée par les droits) ; sinon ne fait rien — l'adresse se recalera
  /// sur l'écran affiché.
  static void select(
    NavigationBloc bloc,
    String? subMenuId,
    AppLocalizations l10n,
  ) {
    final target = subMenuId == null || subMenuId.isEmpty
        ? MenuConstants.accueilId
        : subMenuId;
    if (bloc.state.selectedSubMenuId == target) return;
    if (target == MenuConstants.accueilId) {
      bloc.add(
        SubMenuItemSelected(
          menuId: MenuConstants.accueilId,
          subMenuId: MenuConstants.accueilId,
          title: l10n.home,
        ),
      );
      return;
    }
    for (final menu in bloc.state.menuItems) {
      for (final subMenu in menu.subMenus) {
        if (subMenu.id == target) {
          bloc.add(
            SubMenuItemSelected(
              menuId: menu.id,
              subMenuId: subMenu.id,
              title: subMenu.title,
            ),
          );
          return;
        }
      }
    }
  }

  @override
  State<ShellLocationSync> createState() => _ShellLocationSyncState();
}

class _ShellLocationSyncState extends State<ShellLocationSync> {
  @override
  void didUpdateWidget(covariant ShellLocationSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subMenuId == widget.subMenuId) return;
    ShellLocationSync.select(
      context.read<NavigationBloc>(),
      widget.subMenuId,
      AppLocalizations.of(context)!,
    );
  }

  void _writeLocation(BuildContext context, NavigationState state) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final location = AppRoutesNames.homeSubMenuPath(state.selectedSubMenuId);
    if (AppRoutesNames.homeSubMenuPath(widget.subMenuId) == location) return;
    router.go(location);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<NavigationBloc, NavigationState>(
        listenWhen: (previous, current) =>
            previous.selectedSubMenuId != current.selectedSubMenuId,
        listener: _writeLocation,
        child: widget.child,
      );
}
