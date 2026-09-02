import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Le client règle en… », posé **par devise du panier**.
///
/// ## Pourquoi par devise et non par article
///
/// C'est la transposition exacte du guichet, où la question se pose frais par
/// frais : elle se pose sur le **montant dû**, là où elle a une réponse. À la
/// boutique, ce montant est le sous-total d'une devise de catalogue — un panier
/// qui mêle des uniformes en dollars et des manuels en francs la pose deux fois,
/// une par unité. La poser par article n'ajouterait rien : trois cahiers du même
/// prix se règlent d'un seul geste.
///
/// ## Le cas courant ne coûte rien
///
/// Sans taux paramétré, il n'y a **rien à choisir** : la section disparaît, et
/// l'écran est celui d'avant.
///
/// ## Une seule case saisissable, et c'est voulu
///
/// Le montant dû n'est pas saisi ici — il vient du panier, prix par prix. Reste
/// donc le montant **posé sur le comptoir**, pré-rempli par la conversion et
/// modifiable : le client tend un billet rond, l'écart repart en monnaie rendue
/// plutôt que d'éteindre ce que personne n'a payé.
class BoutiqueTenderSection extends StatefulWidget {
  final BoutiqueCart cart;

  /// La série de taux de l'école. Vide ⇒ la section n'existe pas.
  final List<ExchangeRate> rates;

  final void Function(String catalogCurrency, String currency)?
  onCurrencyChanged;
  final void Function(String catalogCurrency, int? tenderedCents)?
  onTenderedChanged;

  const BoutiqueTenderSection({
    super.key,
    required this.cart,
    this.rates = const [],
    this.onCurrencyChanged,
    this.onTenderedChanged,
  });

  @override
  State<BoutiqueTenderSection> createState() => _BoutiqueTenderSectionState();
}

class _BoutiqueTenderSectionState extends State<BoutiqueTenderSection> {
  /// Un contrôleur par devise de catalogue, créé à la demande.
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String currency) =>
      _controllers.putIfAbsent(currency, TextEditingController.new);

  /// Écrit la valeur dérivée sans déplacer un curseur pour rien.
  void _write(TextEditingController target, String text) {
    if (target.text == text) return;
    target.text = text;
  }

  String _plain(int cents) {
    final amount = cents / 100;
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settlement = TenderSettlement(
      rates: widget.rates,
      at: DateTime.now(),
    );
    final dues = widget.cart.totals.withoutZeros.entries.toList();

    final blocks = <Widget>[];
    for (final due in dues) {
      final options = settlement.optionsFor(due.currency);
      // Une seule option, c'est une absence de choix : l'offrir dirait au
      // comptoir qu'il peut faire quelque chose qu'il ne peut pas.
      if (options.length < 2) continue;

      final tender = widget.cart.tenderFor(due.currency);
      final target = tender.currency.isEmpty ? due.currency : tender.currency;
      final controller = _controllerFor(due.currency);
      final converted = target != due.currency;

      // Le dû converti, toujours : une vente est comptant **intégral**, le prix
      // du panier ne se négocie pas au comptoir. Ce que le client pose ne change
      // donc pas ce qui entre dans le tiroir — seulement ce qui lui revient.
      final line = settlement.fromSettled(
        settledCurrency: due.currency,
        tenderCurrency: target,
        settledCents: due.amountInCents,
      );
      final tendered = tender.tenderedCents ?? 0;
      final change = tendered > line.tenderCents
          ? tendered - line.tenderCents
          : 0;
      final shortfall = tendered > 0 && tendered < line.tenderCents
          ? line.tenderCents - tendered
          : 0;

      // Le champ suit la conversion tant que le comptoir n'a rien tapé ; dès
      // qu'il tape, c'est lui qui décide et on ne réécrit plus rien.
      if (!converted) {
        _write(controller, '');
      } else if (tender.tenderedCents == null) {
        _write(controller, _plain(line.tenderCents));
      }

      blocks.add(
        _TenderBlock(
          due: due,
          options: options,
          selected: target,
          controller: controller,
          converted: converted,
          expected: converted ? _plain(line.tenderCents) : null,
          rate: line.rate,
          changeCents: change,
          shortfallCents: shortfall,
          onCurrencyChanged: (currency) =>
              widget.onCurrencyChanged?.call(due.currency, currency),
          onTenderedChanged: (raw) {
            final parsed = parseMonetaryAmount(raw);
            widget.onTenderedChanged?.call(
              due.currency,
              parsed == null || parsed <= 0 ? null : (parsed * 100).round(),
            );
          },
          l10n: l10n,
        ),
      );
    }

    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          blocks[i],
          if (i < blocks.length - 1)
            const SizedBox(height: AppDimensions.spacingS),
        ],
        const SizedBox(height: AppDimensions.spacingS),
      ],
    );
  }
}

class _TenderBlock extends StatelessWidget {
  final Money due;
  final List<String> options;
  final String selected;
  final TextEditingController controller;
  final bool converted;
  final String? expected;
  final ExchangeRate? rate;
  final int changeCents;

  /// Ce qui manque encore, quand le client a posé moins que le dû. Une vente est
  /// intégrale : on le dit, plutôt que d'écrire une vente à moitié payée.
  final int shortfallCents;

  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onTenderedChanged;
  final AppLocalizations l10n;

  const _TenderBlock({
    required this.due,
    required this.options,
    required this.selected,
    required this.controller,
    required this.converted,
    required this.expected,
    required this.rate,
    required this.changeCents,
    required this.shortfallCents,
    required this.onCurrencyChanged,
    required this.onTenderedChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Le sous-total concerné est nommé : sur un panier à deux devises,
            // deux blocs identiques ne se distingueraient pas autrement.
            l10n.boutiqueTenderCurrency(MoneyFormat.format(due)),
            style: AppTextStyles.badge.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          SegmentedTabFilter<String>(
            expand: true,
            selected: selected,
            onSelected: onCurrencyChanged,
            semanticsLabel: l10n.boutiqueTenderCurrency(
              MoneyFormat.format(due),
            ),
            options: [
              for (final currency in options)
                SegmentedTabOption<String>(
                  label: MoneyFormat.symbolOf(currency),
                  value: currency,
                  semanticLabel: currency,
                ),
            ],
          ),
          if (converted) ...[
            const SizedBox(height: AppDimensions.spacingS),
            CurrencyField(
              controller: controller,
              currency: MoneyFormat.symbolOf(selected),
              labelText: l10n.boutiqueTenderReceivedLabel,
              onChanged: onTenderedChanged,
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Wrap(
              spacing: AppDimensions.spacingM,
              runSpacing: AppDimensions.spacingXS,
              children: [
                if (rate case final applied?)
                  Text(
                    '${applied.formatted()} '
                    '${MoneyFormat.symbolOf(applied.quote)} / '
                    '${MoneyFormat.symbolOf(applied.base)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                if (changeCents > 0)
                  Text(
                    l10n.boutiqueTenderChangeDue(
                      MoneyFormat.format(Money.parse(changeCents, selected)),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.terreCuiteDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (shortfallCents > 0)
                  Text(
                    l10n.boutiqueTenderShortfall(
                      MoneyFormat.format(Money.parse(shortfallCents, selected)),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
