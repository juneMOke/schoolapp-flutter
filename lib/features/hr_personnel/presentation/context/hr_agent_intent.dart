import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ce que l'écran qui ouvre la fiche d'un agent lui passe (`extra`) : de quoi
/// le prévenir quand elle se referme. **Pas l'agent** : la fiche le relit
/// toujours dans le fichier local (`HrAgentRoutePage`).
///
/// ⚠️ Suivant du navigateur rejoue la pile poussée avec ce même `extra` : un
/// agent transporté ici reviendrait tel qu'il était à l'ouverture, et une
/// modification faite depuis serait écrasée au prochain enregistrement.
class HrAgentIntent {
  /// Appelé quand la fiche disparaît, quelle que soit la sortie. Sans effet
  /// après la première fois.
  final VoidCallback onClosed;

  const HrAgentIntent({required this.onClosed});

  /// Ouvre la fiche de [agentId] par-dessus l'écran [subMenuId] — elle prend
  /// son adresse — et se termine quand elle se referme.
  ///
  /// ⚠️ Le `Future` de `push` ne se termine pas quand Précédent du navigateur
  /// retire la fiche (nouvelle configuration, pas un `pop`) : c'est la page
  /// qui prévient, à sa disparition ([onClosed]).
  static Future<void> open(
    BuildContext context, {
    required String subMenuId,
    required String agentId,
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
              agentId: agentId,
            ),
            extra: HrAgentIntent(onClosed: finish),
          )
          .whenComplete(finish),
    );
    return closed.future;
  }
}
