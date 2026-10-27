import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche de paie d'un agent, par-dessus le livre :
/// `/home/paie/{agentId}?mois-agent=AAAA-MM`. Le mois porte la clé de la
/// page d'agent, pas `mois` : le livre du dessous, rebâti après F5, lirait
/// sinon le mois de la fiche comme le sien.
abstract final class PayrollAgentNavigation {
  static const subMenuId = MenuConstants.hrPayrollId;

  /// Ouvre la fiche de [agentId] sur le livre de [month].
  static void open(
    BuildContext context, {
    required String agentId,
    required String month,
  }) => unawaited(
    HrAgentIntent.open(
      context,
      subMenuId: subMenuId,
      agentId: agentId,
      query: {HrAgentAddress.monthParam: month},
    ),
  );

  /// Passe à l'agent [agentId] sans empiler : un seul retour ramène au
  /// livre, et F5 rouvre l'agent affiché. [month] est le livre d'entrée, qui
  /// fixe l'ordre de parcours.
  static void step(
    BuildContext context, {
    required String agentId,
    required String month,
  }) => context.replace(
    Uri(
      path: AppRoutesNames.hrPersonnelAgentPath(
        subMenuId: subMenuId,
        agentId: agentId,
      ),
      queryParameters: {HrAgentAddress.monthParam: month},
    ).toString(),
    extra: GoRouterState.of(context).extra,
  );

  /// La flèche de la fiche : dépiler vers le livre.
  static void leave(BuildContext context) =>
      HrAgentAddress.leave(context, subMenuId: subMenuId);
}
