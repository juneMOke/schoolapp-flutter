import 'dart:async';

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

  /// Appelé quand la fiche disparaît, quelle que soit la sortie.
  final VoidCallback? onClosed;

  const HrAgentIntent({
    required this.member,
    required this.kind,
    required this.others,
    required this.today,
    this.onClosed,
  });

  /// Ouvre la fiche de [row] par-dessus l'écran [subMenuId] — elle prend son
  /// adresse — et se termine quand elle se referme.
  ///
  /// ⚠️ Le `Future` de `push` ne se termine pas quand Précédent du navigateur
  /// retire la fiche (nouvelle configuration, pas un `pop`) : c'est la page
  /// qui prévient, à sa disparition ([onClosed]).
  static Future<void> open(
    BuildContext context, {
    required String subMenuId,
    required StaffFileRow row,
    required List<StaffMember> others,
    required String today,
  }) {
    final closed = Completer<void>();
    void finish() {
      if (!closed.isCompleted) closed.complete();
    }

    unawaited(
      context
          .push<void>(
            AppRoutesNames.hrPersonnelAgentPath(
              subMenuId: subMenuId,
              agentId: row.member.id,
            ),
            extra: HrAgentIntent(
              member: row.member,
              kind: row.kind,
              others: others,
              today: today,
              onClosed: finish,
            ),
          )
          .whenComplete(finish),
    );
    return closed.future;
  }

  /// La fiche d'un agent que cette tablette n'a pas (encore) dans son
  /// fichier : sans `extra`, la page le relit — et tire les flux s'il manque.
  static Future<void> openById(
    BuildContext context, {
    required String subMenuId,
    required String agentId,
  }) => context.push<void>(
    AppRoutesNames.hrPersonnelAgentPath(subMenuId: subMenuId, agentId: agentId),
  );
}
