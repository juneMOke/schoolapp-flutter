import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Un bandeau d'une ligne dans un formulaire : avertissement non bloquant
/// (ambre) ou erreurs à corriger (rouge).
class EteeloNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color ink;
  final Color background;
  final Color? border;
  final EdgeInsetsGeometry margin;

  /// Un geste au bout du bandeau (« Les passer en revue »), dans la même
  /// ligne plutôt que dessous.
  final Widget? action;

  const EteeloNotice._(
    this.message,
    this.icon,
    this.ink,
    this.background, {
    this.action,
  }) : border = null,
       margin = const EdgeInsets.only(bottom: AppSpacing.md);

  /// Un bandeau dans une teinte donnée (celle d'un statut de présence), sans
  /// marge : c'est son conteneur qui l'espace.
  const EteeloNotice.tinted({
    super.key,
    required this.message,
    required this.icon,
    required this.ink,
    required this.background,
    this.border,
    this.margin = EdgeInsets.zero,
    this.action,
  });

  factory EteeloNotice.warning(String message, {Widget? action}) =>
      EteeloNotice._(
        message,
        Icons.info_outline,
        AppColors.staffPartialInk,
        AppColors.feeStatusPartialSoft,
        action: action,
      );

  factory EteeloNotice.error(String message) => EteeloNotice._(
    message,
    Icons.error_outline,
    AppColors.error,
    AppColors.feeStatusDueSoft,
  );

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppRadius.brMd,
      border: border == null ? null : Border.all(color: border!),
    ),
    // Sans geste, pas de LayoutBuilder : le bandeau reste mesurable dans une
    // boîte de dialogue à largeur intrinsèque.
    child: action == null
        ? _line(null, below: false)
        : LayoutBuilder(
            builder: (context, constraints) => _line(
              action,
              below: constraints.maxWidth < AppBreakpoints.formGridTwoColMin,
            ),
          ),
  );

  /// Étroit ([below]), le geste passe sous le texte : à côté, il le
  /// réduisait à une colonne de quelques mots.
  Widget _line(Widget? action, {required bool below}) {
    final text = Text(
      message,
      style: AppTypography.bodySmall.copyWith(color: ink),
    );
    return Row(
      children: [
        Icon(icon, size: 18, color: ink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: below && action != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [text, action],
                )
              : text,
        ),
        if (action != null && !below) ...[
          const SizedBox(width: AppSpacing.sm),
          action,
        ],
      ],
    );
  }
}
