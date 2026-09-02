import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rate_settings_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le taux de guichet, posé par la direction.
///
/// **Sans cet écran, la bascule de devise du guichet n'existe pas** : rien
/// d'autre n'écrit dans le référentiel local, et un caissier ne peut pas
/// inventer un taux. C'est la porte d'entrée de tout le chantier bi-devise.
///
/// **Un palier par enregistrement.** Reposer un taux n'écrase pas le précédent :
/// il en ajoute un, daté. Les versements déjà encaissés gardent celui qui valait
/// alors — c'est ce qui permet de réimprimer un ticket six mois plus tard sans
/// que ses chiffres bougent.
///
/// **Les deux sens se saisissent séparément**, et l'inverse n'est jamais dérivé :
/// 1 ÷ 2 850 tombe sur 0,000350877…, et l'arrondi ferait diverger les deux sens
/// d'un même taux. Une école qui encaisse dans les deux monnaies pose deux
/// lignes, chacune avec le chiffre qu'elle annonce à son guichet.
class ExchangeRateSettingsCard extends StatefulWidget {
  const ExchangeRateSettingsCard({super.key});

  @override
  State<ExchangeRateSettingsCard> createState() =>
      _ExchangeRateSettingsCardState();
}

class _ExchangeRateSettingsCardState extends State<ExchangeRateSettingsCard> {
  final _rateController = TextEditingController();
  String _base = CurrencyCode.usd;
  String _quote = CurrencyCode.cdf;

  static const List<String> _currencies = [
    CurrencyCode.usd,
    CurrencyCode.cdf,
    CurrencyCode.eur,
  ];

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  /// Le taux saisi, en micro-unités. `null` tant que la saisie n'est pas un
  /// nombre strictement positif.
  ///
  /// Deux décimales, celles qui seront stockées : ce que la direction tape, ce
  /// que le guichet affiche et ce que le ticket imprime sont le même nombre.
  int? get _rateMicros {
    final parsed = parseMonetaryAmount(_rateController.text);
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 100).round() * (ExchangeRate.scale ~/ 100);
  }

  List<EteeloSelectItem<String>> get _items => [
    for (final currency in _currencies)
      EteeloSelectItem<String>(
        value: currency,
        label: '$currency · ${MoneyFormat.symbolOf(currency)}',
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ExchangeRateSettingsCubit, ExchangeRateSettingsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ExchangeRateSettingsStatus.saved) {
          _rateController.clear();
          AppSnackBar.showSuccess(context, l10n.exchangeRateSettingsSaved);
        }
        if (state.status == ExchangeRateSettingsStatus.failed) {
          AppSnackBar.showError(
            context,
            state.errorMessage ?? l10n.facturationDetailUnknownValue,
          );
        }
      },
      builder: (context, state) {
        final current = state.currentFor(base: _base, quote: _quote);
        final saving = state.status == ExchangeRateSettingsStatus.saving;
        final canSave = _rateMicros != null && _base != _quote && !saving;

        return FinanceSectionCard(
          backgroundColor: AppColors.surfaceRaised,
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinanceSectionHeader(
                icon: Icons.currency_exchange_rounded,
                title: l10n.exchangeRateSettingsTitle,
                subtitle: l10n.exchangeRateSettingsSubtitle,
                accent: AppColors.bleuArdoise,
                accentSoft: AppColors.surfaceAlt,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              // L'état d'abord : ce qui vaut aujourd'hui, ou le fait qu'il n'y a
              // rien — et ce que ça implique au guichet, dit en toutes lettres.
              Text(
                current == null
                    ? l10n.exchangeRateSettingsNone
                    : l10n.exchangeRateSettingsCurrent(
                        MoneyFormat.symbolOf(_base),
                        current.formatted(),
                        MoneyFormat.symbolOf(_quote),
                      ),
                style: AppTextStyles.caption.copyWith(
                  color: current == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              LayoutBuilder(
                builder: (context, constraints) {
                  final champs = <Widget>[
                    EteeloSelectInput<String>(
                      label: l10n.exchangeRateSettingsFromLabel,
                      items: _items,
                      value: _base,
                      enabled: !saving,
                      onChanged: (value) =>
                          setState(() => _base = value ?? _base),
                    ),
                    EteeloSelectInput<String>(
                      label: l10n.exchangeRateSettingsToLabel,
                      items: _items,
                      value: _quote,
                      enabled: !saving,
                      onChanged: (value) =>
                          setState(() => _quote = value ?? _quote),
                    ),
                    CurrencyField(
                      controller: _rateController,
                      currency: MoneyFormat.symbolOf(_quote),
                      enabled: !saving,
                      labelText: l10n.exchangeRateSettingsValueLabel,
                      onChanged: (_) => setState(() {}),
                    ),
                  ];

                  // Sur une tablette en paysage les trois champs tiennent sur
                  // une ligne ; en portrait ils s'empilent plutôt que de se
                  // comprimer à l'illisible.
                  if (constraints.maxWidth < 640) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final champ in champs) ...[
                          champ,
                          const SizedBox(height: AppDimensions.spacingS),
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < champs.length; i++) ...[
                        Expanded(child: champs[i]),
                        if (i < champs.length - 1)
                          const SizedBox(width: AppDimensions.spacingS),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: canSave
                      ? () => context.read<ExchangeRateSettingsCubit>().save(
                          base: _base,
                          quote: _quote,
                          rateMicros: _rateMicros!,
                        )
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.exchangeRateSettingsSave),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
