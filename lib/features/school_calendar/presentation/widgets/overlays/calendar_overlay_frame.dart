import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/dialog_height.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'en-tête des sur-couches du calendrier (maquette `Modal`) : le bandeau
/// sombre du socle — sur-titre or-doux, titre blanc, ✕ — et, sur une feuille
/// du bas, la poignée posée dessus.
class CalendarOverlayHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final VoidCallback onClose;

  /// Vrai sur une feuille du bas : la poignée, et les coins hauts arrondis.
  final bool sheet;

  const CalendarOverlayHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.onClose,
    this.sheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final header = EteeloDialogDarkHeader(
      eyebrow: eyebrow,
      title: title,
      onClose: onClose,
      // Le titre de la maquette : Inter 18, sur deux lignes au besoin.
      titleStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.textOnDark,
      ),
      titleMaxLines: 2,
    );
    if (!sheet) return header;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: AppRadius.card),
      child: DecoratedBox(
        // Le dégradé du bandeau, prolongé sous la poignée.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: header,
            ),
            Positioned(
              top: AppSpacing.sm,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: AppDimensions.sheetHandleWidth,
                  height: AppDimensions.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.textOnDark.withValues(alpha: 0.45),
                    borderRadius: AppRadius.brPill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une sur-couche de saisie du calendrier (O2, O3, O4) : en-tête sombre,
/// corps défilant, actions à droite (maquette). Plein écran sous 760.
class CalendarOverlayDialog extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget body;
  final List<Widget> actions;

  /// L'action principale telle que son bouton la porte : Ctrl+Entrée.
  final VoidCallback? onSubmit;

  /// La ✕ ; par défaut, ferme sans rien rendre.
  final VoidCallback? onClose;

  final double maxWidth;

  const CalendarOverlayDialog({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actions,
    this.onSubmit,
    this.onClose,
    this.maxWidth = AppDimensions.formDialogMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final pad = EteeloAdaptiveDialog.isFullscreen(context)
        ? AppSpacing.lg
        : AppSpacing.xl;
    final close = onClose ?? () => Navigator.of(context).pop();
    return EteeloAdaptiveDialog(
      maxWidth: maxWidth,
      maxHeight: DialogHeight.ofForm(context),
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: EteeloSubmitShortcut(
        onSubmit: onSubmit,
        child: EteeloDialogBody(
          minPinnedHeight: AppDimensions.formDialogMaxHeight / 2,
          header: CalendarOverlayHeader(
            eyebrow: eyebrow,
            title: title,
            onClose: close,
          ),
          body: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
            child: body,
          ),
          footer: [
            Padding(
              padding: EdgeInsets.all(pad),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
