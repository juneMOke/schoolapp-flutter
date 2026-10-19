import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Ouvre une [EteeloAdaptiveDialog] — toujours par ici.
///
/// Sans `SafeArea` de route : en plein écran, la modale pose la sienne et
/// couvre les bandes système ; celle de `showDialog` y laissait voir la page
/// assombrie, et ces bandes restaient une barrière qui fermait la modale —
/// et perdait la saisie — au premier toucher du bord. Plein écran, la
/// barrière ne ferme donc jamais ; centrée, elle suit [barrierDismissible].
Future<T?> showEteeloAdaptiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    useSafeArea: false,
    barrierColor: barrierColor,
    barrierDismissible:
        barrierDismissible && !EteeloAdaptiveDialog.isFullscreen(context),
    builder: builder,
  );
}

/// Une modale centrée sur un grand écran, plein écran sur un téléphone
/// (sous [AppBreakpoints.formDialogFullscreenMax]).
///
/// Centrée sur 360 dp, une modale gardait ses marges de part et d'autre :
/// ~230 dp de champ, une page A4 de ~310 dp. Plein écran, sous les barres
/// système, elle a toute la largeur.
class EteeloAdaptiveDialog extends StatefulWidget {
  final Widget child;

  /// Bornes de la forme centrée ; sans effet en plein écran.
  final double maxWidth;
  final double maxHeight;

  final Color backgroundColor;

  /// Marge de la forme centrée ; `null` : celle de Material.
  final EdgeInsets? insetPadding;
  final Clip clipBehavior;

  /// Arrondi de la forme centrée.
  final BorderRadius borderRadius;

  const EteeloAdaptiveDialog({
    super.key,
    required this.child,
    required this.maxWidth,
    this.maxHeight = double.infinity,
    this.backgroundColor = AppColors.surfaceRaised,
    this.insetPadding,
    this.clipBehavior = Clip.none,
    this.borderRadius = AppRadius.brCard,
  });

  /// La forme que prend la modale dans [context].
  static bool isFullscreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.formDialogFullscreenMax;

  @override
  State<EteeloAdaptiveDialog> createState() => _EteeloAdaptiveDialogState();
}

class _EteeloAdaptiveDialogState extends State<EteeloAdaptiveDialog> {
  // Tourner le téléphone fait passer la modale de plein écran à centrée : les
  // deux formes n'ont pas le même arbre. Sous cette clé, le contenu est
  // DÉPLACÉ, pas remonté — la saisie et l'aperçu survivent à la rotation.
  final _contentKey = GlobalKey(debugLabel: 'adaptive-dialog-content');

  @override
  Widget build(BuildContext context) {
    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    if (EteeloAdaptiveDialog.isFullscreen(context)) {
      return Dialog.fullscreen(
        backgroundColor: widget.backgroundColor,
        child: SafeArea(child: content),
      );
    }
    return Dialog(
      backgroundColor: widget.backgroundColor,
      surfaceTintColor: Colors.transparent,
      clipBehavior: widget.clipBehavior,
      insetPadding: widget.insetPadding,
      shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: widget.maxHeight,
        ),
        child: content,
      ),
    );
  }
}
