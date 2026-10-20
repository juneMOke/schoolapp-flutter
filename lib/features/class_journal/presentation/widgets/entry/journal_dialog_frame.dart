import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Le cadre des modales du journal : 720 dp de large, plein écran sur un
/// téléphone — au même seuil que toute modale de saisie : une fenêtre de 800
/// tient une modale de 720, elle n'a pas à la recevoir en plein écran.
///
/// S'ouvre par `showEteeloAdaptiveDialog`.
class JournalDialogFrame extends StatelessWidget {
  final Widget child;

  const JournalDialogFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => EteeloAdaptiveDialog(
    maxWidth: AppDimensions.journalModalWidth,
    insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
