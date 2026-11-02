import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_level_labels.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_sale_detail_page.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche d'une vente, enfant du tableau de bord de la boutique :
/// `/home/boutique-tableau-de-bord/vente/{saleId}` (dans la coquille) ou
/// `/boutique/boutique-tableau-de-bord/vente/{saleId}` (hors d'elle).
///
/// Aucun `extra` : la fiche se relit par son seul identifiant, et les
/// libellés de niveau du ticket se recalculent depuis le contexte académique.
/// Une adresse rechargée rebâtit le tableau de bord et pose la fiche
/// par-dessus ; Retour rend le tableau de bord.
abstract final class BoutiqueSaleRoutes {
  static GoRoute sale() => GoRoute(
    path: AppRoutesNames.boutiqueSaleRoute,
    // Sous un autre écran de la coquille, l'adresse retombe sur l'écran.
    redirect: (context, state) {
      final subMenuId = state.pathParameters['subMenuId'];
      return subMenuId == null || subMenuId == MenuConstants.boutiqueDashboardId
          ? null
          : AppRoutesNames.homeSubMenuPath(subMenuId);
    },
    builder: (context, state) => BoutiqueSaleDetailPage(
      saleId: state.pathParameters['saleId'] ?? '',
      levelLabels: boutiqueLevelLabels(
        context.read<AcademicYearContextBloc>().state.context,
      ),
    ),
  );
}
