import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'enveloppe commune des modales de saisie courtes — Pointage, appel des
/// élèves, Paie : un surtitre, un titre, un corps défilant et des actions
/// ancrées. Toutes ont une saisie ou une case : elles passent par
/// [EteeloDialogBody], qui tient au clavier ouvert en paysage.
///
/// Sur un téléphone (sous [AppBreakpoints.formDialogFullscreenMax]), la
/// modale prend tout l'écran.
class EteeloFormDialog extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget body;
  final List<Widget> actions;

  /// Action placée à gauche, séparée des autres (retirer, effacer).
  final Widget? leading;

  /// Largeur maximale ; celle des modales de saisie par défaut.
  final double maxWidth;

  /// L'action principale, telle que son bouton la porte (nulle quand il est
  /// désactivé) : Ctrl+Entrée la déclenche, cf. [EteeloSubmitShortcut].
  final VoidCallback? onSubmit;

  const EteeloFormDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.eyebrow,
    this.leading,
    this.maxWidth = AppDimensions.formDialogMaxWidth,
    this.onSubmit,
  });

  /// Ouvre [dialog] ; rend la valeur passée à `Navigator.pop`.
  static Future<T?> show<T>(BuildContext context, Widget dialog) =>
      showDialog<T>(context: context, builder: (_) => dialog);

  @override
  Widget build(BuildContext context) {
    final fullscreen =
        MediaQuery.sizeOf(context).width <
        AppBreakpoints.formDialogFullscreenMax;
    final content = EteeloSubmitShortcut(
      onSubmit: onSubmit,
      child: Padding(
        padding: EdgeInsets.all(fullscreen ? AppSpacing.lg : AppSpacing.xl),
        child: EteeloDialogBody(
          minPinnedHeight: AppDimensions.formDialogMaxHeight / 2,
          header: _header(),
          body: body,
          footer: _footer(),
        ),
      ),
    );
    if (fullscreen) {
      // Téléphone : tout l'écran, sous les barres système.
      return Dialog.fullscreen(
        backgroundColor: AppColors.surfaceRaised,
        child: SafeArea(child: content),
      );
    }
    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: AppDimensions.formDialogMaxHeight,
        ),
        child: content,
      ),
    );
  }

  Widget _header() {
    final eyebrow = this.eyebrow;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _footer() => [
    const SizedBox(height: AppSpacing.lg),
    Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.sm,
      spacing: AppSpacing.sm,
      children: [
        ?leading,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions,
        ),
      ],
    ),
  ];
}
