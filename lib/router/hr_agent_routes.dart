import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_agent_route_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche d'un agent, enfant de l'écran de la coquille qui l'a ouverte :
/// `/home/{sousMenu}/{agentId}` — sa fiche du personnel sous RH · Personnel,
/// sa présence du mois (`?mois=`) sous le tableau de bord de RH · Présences. Une adresse rechargée rebâtit la coquille
/// (même clé de page) et pose la fiche par-dessus ; Retour rend l'écran.
abstract final class HrAgentRoutes {
  /// Les écrans qui ouvrent une fiche d'agent — les autres sous-menus n'ont
  /// pas d'enfant : leur adresse à trois segments retombe sur l'écran.
  static const subMenuIds = {
    MenuConstants.hrPersonnelDashboardId,
    MenuConstants.hrPersonnelFileId,
    MenuConstants.hrPresenceDashboardId,
    MenuConstants.hrPresenceFicheId,
    MenuConstants.hrPresenceRecapId,
  };

  static GoRoute agent() => GoRoute(
    path: ':agentId',
    // Précédent du navigateur : la même question qu'une saisie quittée.
    onExit: RouteExitGuard.onExit,
    redirect: (context, state) =>
        redirectFor(state.pathParameters['subMenuId']),
    builder: (context, state) {
      final extra = state.extra;
      final onClosed = extra is HrAgentIntent ? extra.onClosed : null;
      final subMenuId = state.pathParameters['subMenuId'];
      if (subMenuId == MenuConstants.hrPresenceDashboardId) {
        return HrPresenceAgentPage(
          args: (
            agentId: state.pathParameters['agentId'] ?? '',
            month: state.uri.queryParameters[HrAgentAddress.monthParam],
            yearStart: null,
          ),
          onClosed: onClosed,
        );
      }
      if (subMenuId == MenuConstants.hrPresenceFicheId ||
          subMenuId == MenuConstants.hrPresenceRecapId) {
        final query = state.uri.queryParameters;
        return HrPresenceFicheAgentPage(
          args: (
            agentId: state.pathParameters['agentId'] ?? '',
            yearly: query[HrAgentAddress.viewParam] == HrAgentAddress.yearValue,
            month: query[HrAgentAddress.monthParam],
            yearStart: null,
          ),
          onClosed: onClosed,
          shellSubMenuId: subMenuId!,
        );
      }
      return HrAgentRoutePage(
        subMenuId: state.pathParameters['subMenuId'] ?? '',
        agentId: state.pathParameters['agentId'] ?? '',
        onClosed: onClosed,
      );
    },
  );

  /// `null` sous un écran de RH · Personnel ; sinon l'écran lui-même.
  static String? redirectFor(String? subMenuId) =>
      subMenuIds.contains(subMenuId)
      ? null
      : AppRoutesNames.homeSubMenuPath(subMenuId);
}
