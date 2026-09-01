import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de recherche du panneau d'options.
///
/// Volontairement plate (fond `surfaceAlt`, pas de bordure) : dans un panneau
/// déjà encadré et ombré, un second champ encadré ferait deux boîtes
/// imbriquées et alourdirait ce qui doit rester un filtre.
class EteeloSelectSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  const EteeloSelectSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: EteeloSelectConstants.searchFieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceAlt,
          hintText: l10n?.selectSearchPlaceholder,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: EteeloSelectConstants.searchIconSize,
            color: AppColors.textMuted,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: AppSpacing.xl + AppSpacing.sm,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: EteeloSelectConstants.searchIconSize,
                ),
                color: AppColors.textMuted,
                tooltip: l10n?.selectSearchClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.xl + AppSpacing.sm,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  focusNode.requestFocus();
                },
              );
            },
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: AppSpacing.xl + AppSpacing.sm,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          border: const OutlineInputBorder(
            borderRadius: AppRadius.brSm,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brSm,
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brSm,
            borderSide: BorderSide(
              color: AppColors.bleuArdoise,
              width: EteeloSelectConstants.restBorderWidth,
            ),
          ),
        ),
      ),
    );
  }
}
