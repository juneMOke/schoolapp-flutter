import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Un groupe numéroté de la modale (« 01 IDENTIFICATION »), séparé du
/// précédent par un filet.
class ChapitreFormGroup extends StatelessWidget {
  final int numero;
  final String title;
  final List<Widget> children;

  const ChapitreFormGroup({
    super.key,
    required this.numero,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final header = Semantics(
      header: true,
      child: Row(
        children: [
          Text(
            numero.toString().padLeft(2, '0'),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.terreCuite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: EdgeInsets.only(top: numero > 1 ? AppSpacing.lg : 0),
      decoration: numero > 1
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          for (final child in children) ...[
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ],
      ),
    );
  }
}

/// Le libellé d'une section de la modale : nom, « (optionnel) », compteur,
/// et une action alignée à droite.
class ChapitreFormLabel extends StatelessWidget {
  final String label;
  final bool optional;
  final int count;
  final Widget? action;

  const ChapitreFormLabel({
    super.key,
    required this.label,
    this.optional = false,
    this.count = 0,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (optional)
                  TextSpan(
                    text: ' ${l10n.chapitreFormOptional}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            style: AppTypography.labelFormLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?action,
      ],
    );
  }
}

/// Le petit bouton « + Ajouter » des sections.
class ChapitreFormAddButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;

  const ChapitreFormAddButton({super.key, required this.onPressed, this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: ProgrammeLayout.iconMedium),
      label: Text(label ?? AppLocalizations.of(context)!.chapitreFormAdd),
      style: TextButton.styleFrom(foregroundColor: AppColors.bleuArdoise),
    );
  }
}
