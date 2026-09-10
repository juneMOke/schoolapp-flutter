import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois réglages : qui l'on vise, à partir de quel montant, à partir de
/// quand un groupe devient ingérable.
///
/// Le recalcul est **synchrone** : aucun de ces gestes ne rejoue un chargement,
/// et le curseur doit se sentir immédiat.
class RecouvrementSimulationControls extends StatefulWidget {
  const RecouvrementSimulationControls({super.key});

  @override
  State<RecouvrementSimulationControls> createState() =>
      _RecouvrementSimulationControlsState();
}

class _RecouvrementSimulationControlsState
    extends State<RecouvrementSimulationControls> {
  final _thresholdController = TextEditingController();

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  /// Devise du plancher : celle de la sélection quand elle est unique, sinon la
  /// devise pivot. En mixte, la comparaison devient un **arbitrage**, et
  /// l'écran le dit plutôt que de le laisser deviner.
  String _thresholdCurrency(RecouvrementDashboardState dashboard) {
    final currencies = dashboard.rates.map((g) => g.currency).toSet();
    return currencies.length == 1 ? currencies.single : _pivot;
  }

  static const String _pivot = 'USD';

  void _onThresholdChanged(String raw, String currency) {
    // Parsing tolérant : on ne retient que les chiffres. Une valeur illisible
    // vaut « pas de plancher » — donc personne de visé — jamais zéro, qui
    // viserait au contraire toute l'école.
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    context.read<RecouvrementSimulationCubit>().setThreshold(
      digits.isEmpty ? null : Money.parse(int.parse(digits) * 100, currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      buildWhen: (prev, curr) => prev.rates != curr.rates,
      builder: (context, dashboard) {
        final currency = _thresholdCurrency(dashboard);
        final mixed = dashboard.rates.length > 1;

        return BlocConsumer<
          RecouvrementSimulationCubit,
          RecouvrementSimulationState
        >(
          // ⚠️ Le cubit OUBLIE le plancher en quittant son critère ; le champ,
          // lui, garde son texte. Sans cette remise à zéro, revenir sur « a
          // payé moins que… » réafficherait un montant que le calcul ne
          // connaît plus — et l'écran montrerait un chiffre qui ne vise
          // personne.
          listenWhen: (prev, curr) =>
              prev.threshold != null && curr.threshold == null,
          listener: (context, _) => _thresholdController.clear(),
          buildWhen: (prev, curr) =>
              prev.criterion != curr.criterion ||
              prev.criticalPercent != curr.criticalPercent,
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppDimensions.spacingM,
                runSpacing: AppDimensions.spacingM,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: AppDimensions.recouvrementCriterionFieldWidth,
                    child: EteeloSelectInput<RecouvrementCriterion>(
                      label: l10n.recouvrementSimulationWho,
                      value: state.criterion,
                      onChanged: (value) => value == null
                          ? null
                          : context
                                .read<RecouvrementSimulationCubit>()
                                .setCriterion(value),
                      items: [
                        for (final criterion in RecouvrementCriterion.values)
                          EteeloSelectItem<RecouvrementCriterion>(
                            value: criterion,
                            label: recouvrementCriterionLabel(criterion, l10n),
                          ),
                      ],
                    ),
                  ),
                  if (state.needsThreshold)
                    SizedBox(
                      width: AppDimensions.recouvrementThresholdFieldWidth,
                      child: TextField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText:
                              '${l10n.recouvrementThresholdLabel} '
                              '(${MoneyFormat.symbolOf(currency)})',
                        ),
                        onChanged: (raw) => _onThresholdChanged(raw, currency),
                      ),
                    ),
                ],
              ),
              if (state.needsThreshold && mixed) ...[
                const SizedBox(height: AppDimensions.spacingS),
                _MixedWarning(currency: currency),
              ],
              const SizedBox(height: AppDimensions.spacingM),
              _CriticalSlider(percent: state.criticalPercent),
            ],
          ),
        );
      },
    );
  }
}

/// En sélection mixte, la saisie d'un montant devient un arbitrage : on le dit
/// **explicitement**, plutôt que de laisser un chiffre se faire passer pour une
/// mesure exacte.
class _MixedWarning extends StatelessWidget {
  final String currency;

  const _MixedWarning({required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppDimensions.recouvrementWarningMaxWidth,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.financeCrossedSurface,
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Text(
        l10n.recouvrementThresholdMixedWarning(MoneyFormat.symbolOf(currency)),
        style: AppTextStyles.caption,
      ),
    );
  }
}

/// À partir de quelle part conservée un groupe devient ingérable.
///
/// La valeur courante vit dans le **libellé**, pas dans une bulle : une bulle
/// disparaît dès qu'on lâche, et c'est le nombre qu'on veut relire.
class _CriticalSlider extends StatelessWidget {
  final int percent;

  const _CriticalSlider({required this.percent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const min = RecouvrementSimulationState.minCriticalPercent;
    const max = RecouvrementSimulationState.maxCriticalPercent;
    const step = RecouvrementSimulationState.criticalPercentStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recouvrementCriticalLabel(percent),
          style: AppTextStyles.tableHeader,
        ),
        Slider(
          value: percent.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ step,
          // Parlé en toutes lettres : « 60 » seul ne dit pas de quoi.
          label: l10n.recouvrementCriticalA11y(percent),
          activeColor: AppColors.terreCuite,
          onChanged: (value) => context
              .read<RecouvrementSimulationCubit>()
              .setCriticalPercent(value.round()),
        ),
      ],
    );
  }
}

/// Le critère en toutes lettres.
///
/// Partagé : le sélecteur l'affiche, l'aperçu nominatif le rappelle en
/// sous-titre, et le papier le portera. Trois surfaces, une seule phrase — deux
/// copies auraient fini par nommer différemment le même filtre.
String recouvrementCriterionLabel(
  RecouvrementCriterion criterion,
  AppLocalizations l10n,
) => switch (criterion) {
  RecouvrementCriterion.noPayment => l10n.recouvrementCriterionNoPayment,
  RecouvrementCriterion.notSettled => l10n.recouvrementCriterionNotSettled,
  RecouvrementCriterion.belowThreshold =>
    l10n.recouvrementCriterionBelowThreshold,
};
