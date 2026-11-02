import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ouvre la caisse boutique depuis son tableau de bord.
///
/// Dans la coquille, par la navigation interne : la route de la caisse vit
/// hors coquille, et un `context.go` y affichait la page nue — ni barre
/// latérale ni retour, le retour Android fermait l'application. Hors coquille
/// (tableau de bord ouvert par sa route), par la route de la caisse.
void openBoutiqueTill(BuildContext context) {
  NavigationBloc? navigation;
  try {
    navigation = context.read<NavigationBloc>();
  } on ProviderNotFoundException {
    navigation = null;
  }
  if (navigation != null) {
    navigation.add(
      SubMenuItemSelected(
        menuId: MenuConstants.boutiqueMenuId,
        subMenuId: MenuConstants.boutiqueAchatsId,
        title: AppLocalizations.of(context)!.subMenuBoutiqueTill,
      ),
    );
    return;
  }
  GoRouter.maybeOf(context)?.go(AppRoutesNames.boutiqueAchats);
}
