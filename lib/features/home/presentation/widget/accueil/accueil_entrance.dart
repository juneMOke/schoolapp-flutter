import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';

/// Micro-animation d'entrée de la page d'accueil (spec §02).
///
/// L'enfant monte de 12 dp en fondu, avec un décalage de 60 ms par rang.
/// **L'état final est la base** : si les animations sont désactivées
/// (`MediaQuery.disableAnimations` / `prefers-reduced-motion`), l'enfant est
/// affiché immédiatement, à sa place définitive — la page reste simplement
/// visible.
///
/// Cale [EteeloEntrance] sur le rythme ample de la page d'atterrissage ; le
/// reste de l'app entre au tempo par défaut du socle.
class AccueilEntrance extends StatelessWidget {
  /// Rang de l'élément dans la séquence (0 = bandeau, puis une carte par rang).
  final int index;
  final Widget child;

  const AccueilEntrance({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) => EteeloEntrance(
    index: index,
    duration: AccueilUiTokens.entranceDuration,
    offsetY: AccueilUiTokens.entranceOffsetY,
    child: child,
  );
}
