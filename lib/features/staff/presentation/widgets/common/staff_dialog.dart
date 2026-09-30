import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'enveloppe commune des modales RH — Pointage (heure, justification,
/// réglages, rapport, clôture) et Paie : un surtitre, un titre, un corps
/// défilant et des actions ancrées. Toutes ont une saisie ou une case : elles passent par
/// [EteeloDialogBody], qui tient au clavier ouvert en paysage.
class StaffDialog extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget body;
  final List<Widget> actions;

  /// Action placée à gauche, séparée des autres (retirer, effacer).
  final Widget? leading;

  const StaffDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.eyebrow,
    this.leading,
  });

  /// Ouvre [dialog] ; rend la valeur passée à `Navigator.pop`.
  static Future<T?> show<T>(BuildContext context, Widget dialog) =>
      showDialog<T>(context: context, builder: (_) => dialog);

  @override
  Widget build(BuildContext context) {
    final eyebrow = this.eyebrow;
    final leading = this.leading;
    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.staffAttendanceDialogMaxWidth,
          maxHeight: AppDimensions.staffAttendanceDialogMaxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EteeloDialogBody(
            minPinnedHeight: AppDimensions.staffAttendanceDialogMaxHeight / 2,
            header: Padding(
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
            ),
            body: body,
            footer: [
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
            ],
          ),
        ),
      ),
    );
  }
}
