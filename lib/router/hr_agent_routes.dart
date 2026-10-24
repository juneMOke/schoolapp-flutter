import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_agent_route_page.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche d'un agent, enfant de l'écran de la coquille qui l'a ouverte :
/// `/home/{sousMenu}/{agentId}`. Une adresse rechargée rebâtit la coquille
/// (même clé de page) et pose la fiche par-dessus ; Retour rend l'écran.
abstract final class HrAgentRoutes {
  /// Les écrans qui ouvrent une fiche d'agent — les autres sous-menus n'ont
  /// pas d'enfant : leur adresse à trois segments retombe sur l'écran.
  static const subMenuIds = {
    MenuConstants.hrPersonnelDashboardId,
    MenuConstants.hrPersonnelFileId,
  };

  static GoRoute agent() => GoRoute(
    path: ':agentId',
    // Précédent du navigateur : la même question qu'une saisie quittée.
    onExit: RouteExitGuard.onExit,
    redirect: (context, state) =>
        redirectFor(state.pathParameters['subMenuId']),
    builder: (context, state) {
      final agentId = state.pathParameters['agentId'] ?? '';
      final extra = state.extra;
      return HrAgentRoutePage(
        subMenuId: state.pathParameters['subMenuId'] ?? '',
        agentId: agentId,
        intent: extra is HrAgentIntent && extra.member.id == agentId
            ? extra
            : null,
      );
    },
  );

  /// `null` sous un écran de RH · Personnel ; sinon l'écran lui-même.
  static String? redirectFor(String? subMenuId) =>
      subMenuIds.contains(subMenuId)
      ? null
      : AppRoutesNames.homeSubMenuPath(subMenuId);
}
