import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Un champ à plafond, et son compteur : « 312 / 1000 », en chiffres
/// tabulaires, qui passe à l'ambre à 90 % du plafond.
class CountedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final String? placeholder;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final bool multiline;
  final int lines;
  final bool enabled;
  final FocusNode? focusNode;

  /// Une ligne sous le champ, avant le compteur (« Les champs insérés… »).
  final String? hint;

  const CountedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.maxLength,
    required this.onChanged,
    this.placeholder,
    this.errorText,
    this.multiline = false,
    this.lines = 1,
    this.enabled = true,
    this.focusNode,
    this.hint,
  });

  /// Le compteur vire à l'ambre à partir de ce taux du plafond.
  static const double warningRatio = 0.9;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EteeloTextInput(
        controller: controller,
        label: label,
        placeholder: placeholder,
        required: true,
        enabled: enabled,
        focusNode: focusNode,
        errorText: errorText,
        keyboardType: multiline
            ? EteeloTextInputType.multiline
            : EteeloTextInputType.text,
        // Un titre et un message sont du texte libre : première lettre.
        capitalization: EteeloTextCapitalization.sentence,
        minLines: multiline ? lines : null,
        maxLines: multiline ? lines : 1,
        inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
        onChanged: onChanged,
      ),
      const SizedBox(height: AppSpacing.xs),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final count = value.text.characters.length;
          final warn = count >= maxLength * warningRatio;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hint == null
                    ? const SizedBox.shrink()
                    : Text(
                        hint!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$count / $maxLength',
                softWrap: false,
                style: AppTextStyles.caption.copyWith(
                  fontFeatures: AppTextStyles.tabularFigures,
                  color: warn ? AppColors.ambreInk : AppColors.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
