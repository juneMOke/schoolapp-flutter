import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Intitulé posé au-dessus du champ, astérisque comprise.
class EteeloSelectLabel extends StatelessWidget {
  final String label;
  final bool required;

  const EteeloSelectLabel({
    super.key,
    required this.label,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
      style: AppTypography.labelFormLarge.copyWith(
        color: AppColors.textPrimary,
        height: 1.3,
      ),
    );
  }
}

/// Ligne sous le champ : l'erreur, ou à défaut l'aide.
///
/// Jamais les deux : empilées, l'aide se lit comme une seconde erreur, et
/// l'erreur perd le seul endroit où on la cherche.
class EteeloSelectFootnote extends StatelessWidget {
  final String? errorText;
  final String? helperText;

  const EteeloSelectFootnote({
    super.key,
    required this.errorText,
    required this.helperText,
  });

  static bool hasContent({String? errorText, String? helperText}) =>
      (errorText?.isNotEmpty ?? false) || (helperText?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final hasError = errorText?.isNotEmpty ?? false;
    return Text(
      hasError ? errorText! : (helperText ?? ''),
      style: AppTypography.bodySmall.copyWith(
        color: hasError ? AppColors.error : AppColors.textMuted,
        height: 1.35,
      ),
    );
  }
}
