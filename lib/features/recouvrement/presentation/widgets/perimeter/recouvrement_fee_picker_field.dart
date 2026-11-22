import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_fee_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix des frais **en résumé** (spec v2, §4.6 A ; `RecFraisPicker`) :
/// 2 pastilles pleines au poste, 1 au téléphone, puis « +{n} autre(s) », et
/// « Modifier », qui ouvre les cases groupées par devise (O1).
///
/// ⚠️ Écart assumé à l'ancien `RecouvrementFeePicker` (« une pastille cochable
/// par nature ») : les pastilles en ligne débordaient dès 5 frais. Le champ
/// tient sur une ligne quel que soit leur nombre ; la cible tactile est le
/// champ entier.
class RecouvrementFeePickerField extends StatelessWidget {
  final List<FeeNature> natures;
  final List<String> selected;
  final FeeSectionTitlesState titles;
  final ValueChanged<List<String>> onChanged;

  /// Une pastille au lieu de deux : largeur reçue sous 600 dp.
  final bool narrow;

  /// Titre de la feuille : « Quels frais analyser ? » (A) ou « Pour quels
  /// frais ? » (pastille de E).
  final String sheetTitle;

  final bool enabled;

  const RecouvrementFeePickerField({
    super.key,
    required this.natures,
    required this.selected,
    required this.titles,
    required this.onChanged,
    required this.sheetTitle,
    this.narrow = false,
    this.enabled = true,
  });

  Future<void> _open(BuildContext context) => showRecouvrementFeeOptions(
    context,
    title: sheetTitle,
    natures: natures,
    selected: selected,
    titles: titles,
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final max = narrow ? 1 : 2;
    final shown = selected.take(max).toList();
    final more = selected.length - shown.length;
    final indexOf = {for (final (i, n) in natures.indexed) n.feeCode: i};
    final byCode = {for (final n in natures) n.feeCode: n};

    return Semantics(
      button: true,
      label: '${l10n.recouvrementFeesQuestion} · ${l10n.recouvrementFeesEdit}',
      child: Material(
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimensions.recouvrementFeeFieldRadius),
          ),
          side: BorderSide(
            color: RecouvrementV2Tones.feeFieldBorder,
            width: AppDimensions.recoveryControlBorderWidth,
          ),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimensions.recouvrementFeeFieldRadius),
          ),
          onTap: enabled ? () => _open(context) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.recouvrementFeeFieldMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.recoverySpace10,
                AppDimensions.recoverySpace6,
                AppDimensions.recoverySpace7,
                AppDimensions.recoverySpace6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppDimensions.recoverySpace6,
                      runSpacing: AppDimensions.recoverySpace6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final code in shown)
                          _FeeChip(
                            label: recouvrementFeeTitle(code, titles, l10n),
                            symbols: [
                              for (final c
                                  in byCode[code]?.currencies ??
                                      const <String>[])
                                MoneyFormat.symbolOf(c),
                            ],
                            color: RecouvrementV2Tones.feeColor(
                              indexOf[code] ?? 0,
                            ),
                          ),
                        if (more > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.recoverySpace10,
                              vertical: AppDimensions.recoverySpace5,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: AppRadius.brPill,
                            ),
                            child: Text(
                              l10n.recouvrementFeesMore(more),
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.recoverySpace10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.recoverySpace11,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.terreCuite,
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                          AppDimensions.recouvrementFeeEditButtonRadius,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: AppDimensions.recoveryIconSize13,
                          color: AppColors.textOnDark,
                        ),
                        const SizedBox(width: AppDimensions.recoverySpace5),
                        Text(
                          l10n.recouvrementFeesEdit,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOnDark,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.recoverySpace3),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: AppDimensions.recoveryIconSize13,
                          color: AppColors.textOnDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une pastille pleine : le nom court du frais et le symbole de sa devise.
/// Le nom s'élide plutôt que de faire déborder le champ (spec v2, §4.5).
class _FeeChip extends StatelessWidget {
  final String label;
  final List<String> symbols;
  final Color color;

  const _FeeChip({
    required this.label,
    required this.symbols,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.recoverySpace11,
        vertical: AppDimensions.recoverySpace5,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDark,
              ),
            ),
          ),
          for (final symbol in symbols) ...[
            const SizedBox(width: AppDimensions.recoverySpace6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.recoverySpace6,
              ),
              decoration: BoxDecoration(
                color: AppColors.textOnDark.withValues(alpha: 0.22),
                borderRadius: AppRadius.brPill,
              ),
              child: Text(
                symbol,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ouvre le choix des frais (O1) : popover dès 760 de fenêtre, feuille du bas
/// en deçà. Partagé par le champ et la pastille « Sur … » du tableau de bord.
Future<void> showRecouvrementFeeOptions(
  BuildContext context, {
  required String title,
  required List<FeeNature> natures,
  required List<String> selected,
  required FeeSectionTitlesState titles,
  required ValueChanged<List<String>> onChanged,
}) => showEteeloAdaptiveSheet<void>(
  context: context,
  builder: (_) => RecouvrementFeeOptions(
    title: title,
    natures: natures,
    selected: selected,
    titles: titles,
    onChanged: onChanged,
  ),
);
