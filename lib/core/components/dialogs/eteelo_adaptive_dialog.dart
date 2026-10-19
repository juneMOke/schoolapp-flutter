import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Une modale centrée sur un grand écran, plein écran sur un téléphone
/// (sous [AppBreakpoints.formDialogFullscreenMax]).
///
/// Centrée sur 360 dp, une modale gardait ses marges de part et d'autre :
/// ~230 dp de champ, une page A4 de ~310 dp. Plein écran, sous les barres
/// système, elle a toute la largeur.
class EteeloAdaptiveDialog extends StatelessWidget {
  final Widget child;

  /// Bornes de la forme centrée ; sans effet en plein écran.
  final double maxWidth;
  final double maxHeight;

  final Color backgroundColor;

  /// Marge de la forme centrée ; `null` : celle de Material.
  final EdgeInsets? insetPadding;
  final Clip clipBehavior;

  const EteeloAdaptiveDialog({
    super.key,
    required this.child,
    required this.maxWidth,
    this.maxHeight = double.infinity,
    this.backgroundColor = AppColors.surfaceRaised,
    this.insetPadding,
    this.clipBehavior = Clip.none,
  });

  /// La forme que prend la modale dans [context].
  static bool isFullscreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.formDialogFullscreenMax;

  @override
  Widget build(BuildContext context) {
    if (isFullscreen(context)) {
      return Dialog.fullscreen(
        backgroundColor: backgroundColor,
        child: SafeArea(child: child),
      );
    }
    return Dialog(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      clipBehavior: clipBehavior,
      insetPadding: insetPadding,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
