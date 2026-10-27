import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche de paie d'un agent, par-dessus le livre (ou le tableau de bord,
/// le registre des arriérés) :
/// `/home/paie/{agentId}?mois-agent=AAAA-MM`. Le mois porte la clé de la
/// page d'agent, pas `mois` : le livre du dessous, rebâti après F5, lirait
/// sinon le mois de la fiche comme le sien.
abstract final class PayrollAgentNavigation {
  static const subMenuId = MenuConstants.hrPayrollId;

  /// Les écrans de RH · Paie qui ouvrent la fiche, par-dessus eux.
  static const origins = {
    MenuConstants.hrPayrollId,
    MenuConstants.hrPayrollDashboardId,
  };

  /// Ouvre la fiche de [agentId] sur le livre de [month], par-dessus
  /// l'écran [from] ; se termine quand elle se referme. [screenQuery] garde
  /// dans l'adresse ce que l'écran du dessous y tient (son `?mois=`) : après
  /// un F5 sur la fiche, le retour retrouve le même écran.
  static Future<void> open(
    BuildContext context, {
    required String agentId,
    required String month,
    String from = subMenuId,
    Map<String, String> screenQuery = const {},
  }) => HrAgentIntent.open(
    context,
    subMenuId: from,
    agentId: agentId,
    query: {...screenQuery, HrAgentAddress.monthParam: month},
  );

  /// Passe à l'agent [agentId] sans empiler : un seul retour ramène au
  /// livre, et F5 rouvre l'agent affiché. [month] est le livre d'entrée, qui
  /// fixe l'ordre de parcours. Sur le web, l'entrée d'historique est
  /// remplacée ([Router.neglect]) : Précédent ne rejoue pas chaque agent.
  static void step(
    BuildContext context, {
    required String agentId,
    required String month,
  }) {
    final state = GoRouterState.of(context);
    Router.neglect(
      context,
      () => context.replace(
        Uri(
          path: AppRoutesNames.hrPersonnelAgentPath(
            subMenuId: originOf(context),
            agentId: agentId,
          ),
          queryParameters: {
            ...state.uri.queryParameters,
            HrAgentAddress.monthParam: month,
          },
        ).toString(),
        extra: state.extra,
      ),
    );
  }

  /// La flèche de la fiche : dépiler vers l'écran [from] (par défaut,
  /// celui de l'adresse).
  static void leave(BuildContext context, {String? from}) =>
      HrAgentAddress.leave(context, subMenuId: from ?? originOf(context));

  /// Le nom de l'écran sous la fiche : la flèche, le bouton de retour.
  static String backLabel(AppLocalizations l10n, String origin) =>
      origin == MenuConstants.hrPayrollDashboardId
      ? l10n.subMenuDashboard
      : l10n.payrollTabLedger;

  /// L'écran sous la fiche, lu dans l'adresse ; le livre à défaut.
  static String originOf(BuildContext context) {
    final id = GoRouter.maybeOf(context) == null
        ? null
        : GoRouterState.of(context).pathParameters['subMenuId'];
    return origins.contains(id) ? id! : subMenuId;
  }
}
