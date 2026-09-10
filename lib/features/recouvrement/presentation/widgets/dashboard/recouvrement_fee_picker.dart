import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le sélecteur de frais du tableau de bord : **une pastille cochable par
/// nature**, jamais un menu déroulant.
///
/// La sélection définit le sujet de toute la page — « 68 % recouvrés » ne veut
/// rien dire sans savoir sur quoi — et il faut donc la voir en entier, pas
/// derrière un menu qui n'en montre qu'une à la fois.
///
/// ## La dernière pastille ne se décoche pas
///
/// Le clic est **ignoré**, sans message ni erreur : une sélection vide ne rend
/// aucun indicateur calculable, et refuser bruyamment un geste dont personne
/// n'attend qu'il aboutisse ferait passer une garde pour une panne
/// (RECOUVREMENT_PLAN.md, invariant n° 8).
class RecouvrementFeePicker extends StatelessWidget {
  /// Les natures offertes, dans l'ordre du registre — la plus portée d'abord.
  final List<String> feeCodes;

  /// Les natures cochées. Jamais vide dès qu'[feeCodes] ne l'est pas.
  final Set<String> selected;

  final ValueChanged<Set<String>> onChanged;

  /// Grisé pendant une lecture : la sélection est ce qu'on interroge, la
  /// changer en vol produirait deux requêtes pour un seul geste.
  final bool enabled;

  /// Devise de chaque nature, **quand elle n'en a qu'une**.
  ///
  /// ⚠️ Chez nous la devise appartient à la **créance**, pas au frais : rien
  /// n'interdit à une même nature d'exister en francs et en dollars sur le même
  /// périmètre. Une nature absente de cette table n'affiche donc aucun symbole —
  /// et sa présence dans la sélection rend celle-ci mixte. Écrire un symbole au
  /// jugé ferait croire à une devise que la grille ne garantit pas.
  ///
  /// Vide par défaut : le tableau de bord n'affiche pas de symbole.
  final Map<String, String> currencies;

  /// Nom de chaque nature, quand l'écran sait la nommer **par la grille**.
  ///
  /// Le tableau de bord n'en passe pas : il est école-wide, et deux niveaux
  /// nomment la même nature différemment — seule la nature localisée y est
  /// juste. L'écran de contrôle, lui, est borné à un niveau, donc à une grille :
  /// il écrit le nom que l'école a écrit. Une nature absente de cette table
  /// retombe sur son libellé localisé.
  final Map<String, String> labels;

  /// Libellé de la rangée. Les deux écrans du module ne nomment pas la même
  /// chose : le tableau de bord retient des frais pour mesurer, le contrôle en
  /// contrôle.
  final String? label;

  final String? semanticsLabel;

  const RecouvrementFeePicker({
    super.key,
    required this.feeCodes,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.currencies = const <String, String>{},
    this.labels = const <String, String>{},
    this.label,
    this.semanticsLabel,
  });

  void _toggle(String code) {
    final next = Set<String>.from(selected);
    if (next.contains(code)) {
      // La dernière ne se décoche pas — le geste est sans effet, pas fautif.
      if (next.length == 1) return;
      next.remove(code);
    } else {
      next.add(code);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: semanticsLabel ?? l10n.recouvrementFeePickerA11yLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label ?? l10n.recouvrementFeePickerLabel,
            style: AppTextStyles.tableHeader,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              for (final code in feeCodes)
                _FeeChip(
                  code: code,
                  label: labels[code] ?? code.localizedFeeLabel(l10n),
                  currency: currencies[code],
                  checked: selected.contains(code),
                  // Une pastille seule cochée n'est pas décochable : on le dit
                  // à l'assistance vocale plutôt que de la laisser annoncer un
                  // geste qui ne fera rien.
                  locked: selected.length == 1 && selected.contains(code),
                  enabled: enabled,
                  onTap: () => _toggle(code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeChip extends StatelessWidget {
  final String code;
  final String label;

  /// Devise de la nature, `null` quand la grille en porte plusieurs.
  final String? currency;

  final bool checked;
  final bool locked;
  final bool enabled;
  final VoidCallback onTap;

  const _FeeChip({
    required this.code,
    required this.label,
    required this.currency,
    required this.checked,
    required this.locked,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = checked && enabled;
    final currencyCode = currency;
    final symbol = currencyCode == null
        ? ''
        : MoneyFormat.symbolOf(currencyCode);

    return Semantics(
      checked: checked,
      enabled: enabled && !locked,
      label: locked ? l10n.recouvrementFeeChipLockedA11y(label) : label,
      // Le libellé de la pastille est DÉJÀ dans l'étiquette : sans exclusion,
      // il s'y ajouterait une seconde fois et le verrou — la seule chose que
      // l'assistance vocale doit entendre en plus — se noierait dedans.
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled && !locked ? onTap : null,
        borderRadius: BorderRadius.circular(
          AppDimensions.recouvrementFeeChipRadius,
        ),
        child: Container(
          // Cible tactile : la pastille fait 38 de haut, la rangée qui la porte
          // en offre 44 avec son interligne.
          height: AppDimensions.recouvrementFeeChipHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.bleuArdoiseSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(
              AppDimensions.recouvrementFeeChipRadius,
            ),
            border: Border.all(
              color: active ? AppColors.bleuArdoise : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: AppDimensions.recouvrementFeeChipIconSize,
                color: active ? AppColors.bleuArdoise : AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                label,
                style: active
                    ? AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.bleuProfond,
                      )
                    : AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
              ),
              // Le symbole rend la conséquence du clic lisible AVANT le clic :
              // cocher un frais en francs à côté d'un frais en dollars ferme le
              // montant plancher.
              if (symbol.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  symbol,
                  style: AppTextStyles.caption.copyWith(
                    color: active ? AppColors.bleuArdoise : AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
