import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';

/// Rend le texte de [child] sélectionnable et copiable au clavier physique
/// (poste de bureau, navigateur) : on y recopie un matricule, une référence
/// de paiement ou un montant.
///
/// Sur la tablette, rien ne change : un appui long y garde son sens, et la
/// sélection à la volée n'y est pas attendue.
class DesktopSelectionArea extends StatelessWidget {
  final Widget child;

  const DesktopSelectionArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!expectsPhysicalKeyboard) return child;
    return SelectionArea(child: child);
  }
}
