import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ce que l'écran qui ouvre la fiche d'un agent lui passe (`extra`) : l'agent,
/// son contrat du jour, et le reste du fichier pour les doublons.
///
/// Une adresse rechargée ou partagée n'en a pas : la fiche relit alors le
/// fichier local (`HrAgentRoutePage`).
class HrAgentIntent {
  final StaffMember member;
  final StaffContractKind? kind;
  final List<StaffMember> others;
  final String today;

  const HrAgentIntent({
    required this.member,
    required this.kind,
    required this.others,
    required this.today,
  });

  /// Ouvre la fiche de [row] par-dessus l'écran [subMenuId] — elle prend son
  /// adresse — et se termine quand elle se referme.
  static Future<void> open(
    BuildContext context, {
    required String subMenuId,
    required StaffFileRow row,
    required List<StaffMember> others,
    required String today,
  }) => context.push<void>(
    AppRoutesNames.hrPersonnelAgentPath(
      subMenuId: subMenuId,
      agentId: row.member.id,
    ),
    extra: HrAgentIntent(
      member: row.member,
      kind: row.kind,
      others: others,
      today: today,
    ),
  );
}
