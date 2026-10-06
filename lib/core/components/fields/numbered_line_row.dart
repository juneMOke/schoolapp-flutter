import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Une ligne d'une liste numérotée éditable : pastille du numéro, champ de
/// texte, ✕ pour la retirer.
///
/// Partagée par les objectifs d'un chapitre et la liste « Au programme »
/// d'une évaluation. Le ✕ disparaît quand [onRemove] est nul.
class NumberedLineRow extends StatelessWidget {
  final int number;
  final TextEditingController controller;

  /// Libellé lu par l'accessibilité (le champ n'en affiche pas).
  final String label;
  final String? placeholder;
  final String? removeTooltip;
  final VoidCallback? onRemove;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final double badgeSize;

  const NumberedLineRow({
    super.key,
    required this.number,
    required this.controller,
    required this.label,
    this.placeholder,
    this.removeTooltip,
    this.onRemove,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.badgeSize = AppSpacing.xl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NumberedLineBadge(number, size: badgeSize),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: EteeloTextInput(
            controller: controller,
            label: label,
            hideLabel: true,
            placeholder: placeholder,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            capitalization: EteeloTextCapitalization.sentence,
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: removeTooltip,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.error,
          ),
      ],
    );
  }
}

/// La pastille ronde du numéro d'une ligne.
class NumberedLineBadge extends StatelessWidget {
  final int value;
  final double size;

  const NumberedLineBadge(this.value, {super.key, this.size = AppSpacing.xl});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        '$value',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
