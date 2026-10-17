import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';

/// Rend le texte de [child] sélectionnable et copiable au clavier physique
/// (poste de bureau, navigateur) : on y recopie un matricule, une référence
/// de paiement ou un montant.
///
/// Réservé aux fiches EN LECTURE : la zone prend le focus à chaque clic sur
/// du texte (c'est ce qui rend Ctrl+C possible). Sur un écran qui écoute le
/// clavier — la saisie des notes au clavier, par exemple —, ce clic couperait
/// la frappe en cours. Son nœud de focus reste hors de la tabulation, et une
/// zone posée dans une autre ne s'ajoute pas : il n'y en a jamais qu'une.
///
/// Sur la tablette, rien ne change : un appui long y garde son sens.
class DesktopSelectionArea extends StatefulWidget {
  final Widget child;

  const DesktopSelectionArea({super.key, required this.child});

  @override
  State<DesktopSelectionArea> createState() => _DesktopSelectionAreaState();
}

class _DesktopSelectionAreaState extends State<DesktopSelectionArea> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'DesktopSelectionArea',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!expectsPhysicalKeyboard ||
        SelectionContainer.maybeOf(context) != null) {
      return widget.child;
    }
    return SelectionArea(focusNode: _focusNode, child: widget.child);
  }
}
