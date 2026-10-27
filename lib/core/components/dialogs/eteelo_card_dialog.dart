import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/dialog_height.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_actions.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La modale « carte » de l'application : l'en-tête sombre des popins
/// d'Inscription et de Facturation ([EteeloDialogDarkHeader]), un corps qui
/// défile, et un pied d'actions séparé par un filet ([EteeloDialogActions]).
///
/// Une seule forme pour les décisions qui comptent — valider une journée,
/// la quitter sans la valider : titre, contenu, pied, lus comme un tout.
/// Plein écran sur un téléphone ([EteeloAdaptiveDialog]).
class EteeloCardDialog extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget body;

  /// De la plus discrète à la principale.
  final List<Widget> actions;

  /// La croix de l'en-tête ; `null` : referme sans rien rendre.
  final VoidCallback? onClose;

  /// L'action principale (Ctrl+Entrée), nulle quand son bouton est éteint.
  final VoidCallback? onSubmit;
  final double maxWidth;

  const EteeloCardDialog({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actions,
    this.onClose,
    this.onSubmit,
    this.maxWidth = AppDimensions.formDialogMaxWidth,
  });

  /// Ouvre [dialog] ; rend la valeur passée à `Navigator.pop`.
  static Future<T?> show<T>(BuildContext context, Widget dialog) =>
      showEteeloAdaptiveDialog<T>(context: context, builder: (_) => dialog);

  @override
  Widget build(BuildContext context) => EteeloAdaptiveDialog(
    maxWidth: maxWidth,
    maxHeight: DialogHeight.ofForm(context),
    clipBehavior: Clip.antiAlias,
    child: EteeloSubmitShortcut(
      onSubmit: onSubmit,
      child: EteeloDialogBody(
        minPinnedHeight: AppDimensions.formDialogMaxHeight / 2,
        header: EteeloDialogDarkHeader(
          eyebrow: eyebrow,
          title: title,
          onClose: onClose ?? () => Navigator.of(context).pop(),
        ),
        bodyPadding: const EdgeInsets.all(AppSpacing.lg),
        body: body,
        footer: [
          const Divider(height: 1),
          EteeloDialogActions(actions: actions),
        ],
      ),
    ),
  );
}
