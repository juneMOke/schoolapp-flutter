import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_fee_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La première carte de l'écran, et **ce n'est pas un filtre accessoire** :
/// elle définit le sujet de toute la page.
///
/// « 68 % recouvrés » ne veut rien dire sans savoir sur quoi. D'où deux
/// contrôles seulement — les frais retenus et le périmètre — puis une ligne de
/// contexte qui rappelle l'effectif concerné et le taux du jour.
class RecouvrementPerimeterCard extends StatelessWidget {
  /// Sentinelle de « tous les cycles » : `EteeloSelectInput` distingue mal
  /// `null` (rien de choisi) d'un choix explicite de tout voir.
  static const String allCyclesValue = '__all__';

  final List<String> feeCodes;
  final Set<String> selectedFeeCodes;
  final List<FeeControlCycleOption> cycles;
  final String? selectedCycleId;
  final bool enabled;
  final ValueChanged<Set<String>> onFeeCodesChanged;
  final ValueChanged<String?> onCycleChanged;

  /// Effectif **concerné** — celui que le registre a rendu, jamais celui des
  /// inscrits. `null` tant qu'aucune lecture n'a abouti : la ligne de contexte
  /// se tait plutôt que d'annoncer zéro.
  final int? concernedCount;

  /// Inscrits du périmètre que **rien de la sélection ne facture**. `null`
  /// quand on n'a pas pu vérifier — ce qui n'est pas « personne ».
  final int? unbilled;

  /// Le taux de guichet en vigueur, ou `null` si l'école n'en a posé aucun.
  final ExchangeRate? exchangeRate;

  const RecouvrementPerimeterCard({
    super.key,
    required this.feeCodes,
    required this.selectedFeeCodes,
    required this.cycles,
    required this.selectedCycleId,
    required this.onFeeCodesChanged,
    required this.onCycleChanged,
    this.enabled = true,
    this.concernedCount,
    this.unbilled,
    this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final picker = RecouvrementFeePicker(
      feeCodes: feeCodes,
      selected: selectedFeeCodes,
      onChanged: onFeeCodesChanged,
      enabled: enabled,
    );

    final scope = EteeloSelectInput<String>(
      label: l10n.recouvrementScopeLabel,
      value: selectedCycleId ?? allCyclesValue,
      enabled: enabled,
      onChanged: onCycleChanged,
      items: [
        EteeloSelectItem<String>(
          value: allCyclesValue,
          label: l10n.recouvrementScopeAll,
        ),
        for (final option in cycles)
          EteeloSelectItem<String>(value: option.id, label: option.name),
      ],
    );

    return BiToneSectionCard(
      title: l10n.recouvrementScopeLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppBreakpoints.feeControlTableWideMin;
              // Étroit : les pastilles s'enroulent et le périmètre passe
              // dessous, pleine largeur. Large : alignés en bas, le périmètre
              // borné pour que les pastilles gardent la place qui compte.
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    picker,
                    const SizedBox(height: AppDimensions.spacingM),
                    scope,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: picker),
                  const SizedBox(width: AppDimensions.spacingM),
                  SizedBox(
                    width: AppDimensions.recouvrementScopeFieldWidth,
                    child: scope,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _ContextLine(
            concernedCount: concernedCount,
            unbilled: unbilled,
            rate: exchangeRate,
          ),
        ],
      ),
    );
  }
}

/// Ce que la sélection couvre, et à quel taux s'arbitre une comparaison.
///
/// Le taux n'est **jamais** un montant affiché : il ne sert qu'à ordonner et à
/// comparer un plancher. Le rappeler ici, à côté du périmètre, dit d'où vient
/// l'arbitrage sans le faire passer pour une mesure.
class _ContextLine extends StatelessWidget {
  final int? concernedCount;
  final int? unbilled;
  final ExchangeRate? rate;

  const _ContextLine({
    required this.concernedCount,
    required this.unbilled,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = concernedCount;

    // Tant qu'aucune lecture n'a abouti, la ligne se tait : annoncer « 0 élève
    // concerné » avant d'avoir lu serait un chiffre, pas une attente.
    if (count == null) return const SizedBox.shrink();

    final notBilled = unbilled;
    final parts = <String>[
      l10n.recouvrementContextLine(count),
      // Dit seulement quand il y en a. « 0 non facturé » est un bruit ; `null`
      // — on n'a pas pu vérifier — se tait aussi, plutôt que de laisser croire
      // que tout le monde est facturé.
      if (notBilled != null && notBilled > 0)
        l10n.recouvrementUnbilledNote(notBilled),
      rate == null
          ? l10n.recouvrementRateMissing
          : l10n.recouvrementRateLine(rate!.formatted()),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        parts.join(' · '),
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
