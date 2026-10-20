import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/web/new_tab.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ouvre l'écran d'une carte de l'Accueil — dans un nouvel onglet au
/// Ctrl+clic (web), comme le menu latéral.
void openAccueilTarget(BuildContext context, AccueilNavTarget target) {
  if (NewTab.requestedByModifier) {
    NewTab.open(accueilTargetPath(target));
    return;
  }
  context.read<NavigationBloc>().add(
    SubMenuItemSelected(
      menuId: target.menuId,
      subMenuId: target.subMenuId,
      title: target.title,
    ),
  );
}

/// L'adresse de l'écran visé — pour le clic molette (`MiddleClickOpensTab`).
String accueilTargetPath(AccueilNavTarget target) =>
    AppRoutesNames.homeSubMenuPath(target.subMenuId);
