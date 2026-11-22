import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le contenu du choix des frais (spec v2, O1) : **un groupe par devise**, une
/// case par frais, « Tous ceux-ci » par groupe, la ligne ambre si les deux
/// devises sont cochées, et le pied « {n} frais cochés · au moins un reste
/// coché ».
///
/// Le choix s'applique **à chaque case**, sans bouton de validation. Décocher
/// le dernier frais est ignoré : aucun chiffre ne se calcule sans frais.
///
/// Une nature facturée dans **deux** devises (dollars ici, francs là) paraît
/// dans les deux groupes : la cocher dans l'un la coche dans l'autre — c'est
/// la même nature.
class RecouvrementFeeOptions extends StatefulWidget {
  final String title;
  final List<FeeNature> natures;
  final List<String> selected;
  final FeeSectionTitlesState titles;
  final ValueChanged<List<String>> onChanged;

  const RecouvrementFeeOptions({
    super.key,
    required this.title,
    required this.natures,
    required this.selected,
    required this.titles,
    required this.onChanged,
  });

  @override
  State<RecouvrementFeeOptions> createState() => _RecouvrementFeeOptionsState();
}

class _RecouvrementFeeOptionsState extends State<RecouvrementFeeOptions> {
  late List<String> _selected = widget.selected;

  /// L'ordre de l'école, quelle que soit la séquence des clics.
  List<String> _ordered(Set<String> codes) => [
    for (final n in widget.natures)
      if (codes.contains(n.feeCode)) n.feeCode,
  ];

  void _apply(Set<String> codes) {
    if (codes.isEmpty) return;
    final next = _ordered(codes);
    setState(() => _selected = next);
    widget.onChanged(next);
  }

  void _toggle(String code) {
    final codes = _selected.toSet();
    codes.contains(code) ? codes.remove(code) : codes.add(code);
    _apply(codes);
  }

  bool get _mixed {
    final currencies = {
      for (final n in widget.natures)
        if (_selected.contains(n.feeCode)) ...n.currencies,
    };
    return currencies.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencies = {
      for (final n in widget.natures) ...n.currencies,
    }.toList()..sort(_currencyOrder);
    final indexOf = {for (final (i, n) in widget.natures.indexed) n.feeCode: i};

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.bleuProfond,
                  ),
                ),
              ),
              TouchTarget(
                child: IconButton(
                  tooltip: l10n.recouvrementClose,
                  icon: const Icon(
                    Icons.close,
                    size: AppDimensions.detailMiniIconSize,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final currency in currencies)
                    _group(context, currency, [
                      for (final n in widget.natures)
                        if (n.currencies.contains(currency)) n,
                    ], indexOf),
                ],
              ),
            ),
          ),
          if (_mixed)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.all(AppDimensions.recoverySpace9),
              decoration: const BoxDecoration(
                color: AppColors.feeStatusPartialSoft,
                borderRadius: AppRadius.brSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: AppDimensions.recoveryIconSize14,
                    color: AppColors.ambreInk,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.recouvrementFeesMixedNotice,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.ambreInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.recouvrementFeesCheckedFooter(_selected.length),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(
    BuildContext context,
    String currency,
    List<FeeNature> natures,
    Map<String, int> indexOf,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppDimensions.recoverySpace2,
              AppSpacing.xs,
              AppDimensions.recoverySpace6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recouvrementFeesGroupTitle(currency, l10n).toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing:
                          AppDimensions.recoveryOverlineLetterSpacing,
                    ),
                  ),
                ),
                if (natures.length > 1)
                  TextButton(
                    onPressed: () =>
                        _apply({for (final n in natures) n.feeCode}),
                    child: Text(l10n.recouvrementFeesAllOfThese),
                  ),
              ],
            ),
          ),
          for (final n in natures)
            _FeeOption(
              label: recouvrementFeeTitle(n.feeCode, widget.titles, l10n),
              symbol: MoneyFormat.symbolOf(currency),
              color: RecouvrementV2Tones.feeColor(indexOf[n.feeCode] ?? 0),
              checked: _selected.contains(n.feeCode),
              onTap: () => _toggle(n.feeCode),
            ),
        ],
      ),
    );
  }

  /// Les dollars d'abord, comme la maquette (« Frais en dollars », puis « en
  /// francs ») ; toute autre devise ensuite, par code.
  static int _currencyOrder(String a, String b) {
    int rank(String c) => c == 'USD' ? 0 : (c == 'CDF' ? 1 : 2);
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.compareTo(b);
  }
}

/// « Frais en dollars », « Frais en francs », ou le code pour une autre devise.
String recouvrementFeesGroupTitle(String currency, AppLocalizations l10n) =>
    switch (currency) {
      'USD' => l10n.recouvrementFeesGroupUsd,
      'CDF' => l10n.recouvrementFeesGroupCdf,
      _ => l10n.recouvrementFeesGroupOther(currency),
    };

/// Une case de la liste (`RecOpt` multi) : carré coché de la couleur du frais,
/// libellé, symbole de la devise.
class _FeeOption extends StatelessWidget {
  final String label;
  final String symbol;
  final Color color;
  final bool checked;
  final VoidCallback onTap;

  const _FeeOption({
    required this.label,
    required this.symbol,
    required this.color,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        checked: checked,
        button: true,
        child: Material(
          color: checked
              ? Color.alphaBlend(
                  color.withValues(alpha: 0.08),
                  AppColors.surfaceRaised,
                )
              : AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brMd,
            side: BorderSide(
              color: checked ? color : AppColors.border,
              width: AppDimensions.recoveryControlBorderWidth,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.brMd,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppDimensions.recouvrementCheckboxSize,
                      height: AppDimensions.recouvrementCheckboxSize,
                      decoration: BoxDecoration(
                        color: checked ? color : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.recouvrementCheckboxRadius,
                        ),
                        border: Border.all(
                          color: checked ? color : AppColors.borderStrong,
                          width: AppDimensions.recouvrementCheckboxBorderWidth,
                        ),
                      ),
                      child: checked
                          ? const Icon(
                              Icons.check,
                              size: AppDimensions.recoveryIconSize13,
                              color: AppColors.textOnDark,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.recoverySpace11),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: checked ? color : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.recoverySpace7,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        symbol,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
