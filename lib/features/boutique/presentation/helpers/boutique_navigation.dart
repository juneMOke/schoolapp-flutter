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

/// Ouvre la fiche de [saleId] par-dessus le tableau de bord, à son adresse
/// (`…/vente/{saleId}`) ; se termine quand elle se referme. La requête du
/// tableau de bord suit (période, filtres) : après un F5 sur la fiche, le
/// retour retrouve le même écran — et, tant que la fiche est ouverte, il
/// ne lit pas une adresse nue comme un retour à ses valeurs par défaut.
///
/// ⚠️ Précédent du navigateur retire la fiche sans `pop` : le `Future` ne se
/// termine alors pas, et le tableau de bord ne se relit pas.
Future<void> openBoutiqueSale(BuildContext context, {required String saleId}) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return Future.value();
  final here = GoRouterState.of(context).uri;
  return context.push<void>(
    Uri(
      path: AppRoutesNames.boutiqueSalePath(
        dashboardPath: here.path,
        saleId: saleId,
      ),
      queryParameters: here.queryParameters.isEmpty
          ? null
          : here.queryParameters,
    ).toString(),
  );
}
