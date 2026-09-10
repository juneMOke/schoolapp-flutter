import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le **taux du jour**, posé au-dessus de la fenêtre de temps.
///
/// ## Ce qu'il est, et ce qu'il n'est pas
///
/// ⚠️ **Aucun chiffre de cet écran n'en dérive.** La spec justifie le bandeau
/// par « tout montant croisé de l'écran en dépend » ; c'est faux, et c'est la
/// doctrine elle-même qui le dit : « la conversion utilise le taux du reçu pour
/// un fait passé, le taux du jour uniquement pour une projection — et cet écran
/// ne projette pas ». Les lignes croisées de la table portent **le taux qui
/// leur a été appliqué**, parfois vieux de trois jours.
///
/// Le bandeau reste néanmoins juste : il dit ce que l'école a paramétré
/// aujourd'hui, ce qui est exactement ce dont on a besoin pour comprendre
/// qu'un reçu d'hier ne s'aligne pas dessus.
///
/// ## Une seule paire, et aucune sortie — arbitrage du porteur
///
/// ⚠️ **Le bandeau ne montre plus que le dollar contre le franc**, et plus
/// « toutes les paires en vigueur ». Cet écran-ci est un écran de caisse
/// congolais : la paire qui s'y lit est celle qui croise, et une paire exotique
/// qu'une école aurait configurée par ailleurs n'y expliquerait aucune ligne de
/// la table. Conséquence assumée : si une telle paire existe, ce bandeau la
/// tait — le silence est ici volontaire, contrairement à tous les autres de cet
/// écran.
///
/// ⚠️ **Et le lien « Modifier le taux » est retiré.** Le taux se change en
/// Configuration ▸ Réglages, qui reste atteignable par le menu ; le bandeau
/// redevient une lecture, comme le reste de l'écran, où aucune carte n'expose
/// de bouton. Le prix à connaître : « aucun taux paramétré » est désormais un
/// constat sans issue offerte.
///
/// ## La ligne fine est absente FAUTE DE DONNÉE, pas par oubli
///
/// La maquette écrit dessous « Taux du jour · saisi le 04/09/2026 par Moke
/// Junior ». Le socle n'en porte ni moitié : [ExchangeRate] a un
/// `effectiveFrom` — la date à partir de laquelle le taux **vaut** — qui n'est
/// pas sa date de saisie, et aucun champ ne nomme l'auteur. Écrire
/// « saisi le » au-dessus d'`effectiveFrom` mentirait sur un écran de contrôle
/// de caisse ; la ligne est donc omise entière.
///
/// Conséquence assumée : les mots « Taux du jour » disparaissent de l'écran. Ils
/// survivent dans l'étiquette d'accessibilité, faute de quoi un lecteur d'écran
/// annoncerait un nombre nu.
///
/// ## Deux décimales, contre les « 2 850 » de la maquette
///
/// [ExchangeRate.formatted] est **la** façon d'écrire un taux dans cette
/// application, et sa documentation dit pourquoi il n'y en a qu'une : ce nombre
/// s'affiche au guichet ET s'imprime sur le ticket, et deux copies
/// divergeraient au premier ajustement. Un « 2 850 » ici contre « 2 850,00 »
/// sur le reçu ferait douter du même taux.
class FinanceTillRateBar extends StatelessWidget {
  const FinanceTillRateBar({super.key});

  /// Médaillon de 30 dp, rayon 9, tel que la maquette le dessine.
  static const double _medallionSize = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ExchangeRatesCubit, ExchangeRatesState>(
      buildWhen: (prev, curr) =>
          prev.loaded != curr.loaded || prev.rates != curr.rates,
      builder: (context, state) {
        // Rien tant que la série n'a pas répondu : un bandeau qui annoncerait
        // « aucun taux » pendant une lecture en cours dirait faux, et le cubit
        // porte `loaded` précisément pour distinguer « on ne sait pas encore »
        // de « il n'y a rien ».
        if (!state.loaded) return const SizedBox.shrink();

        final rate = _dollarInFrancs(state.rates);

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RateMedallion(size: _medallionSize),
              const SizedBox(width: 16),
              Expanded(
                child: rate == null
                    ? Semantics(
                        label: l10n.financeTillRateNoneA11yLabel,
                        child: ExcludeSemantics(
                          child: Text(
                            l10n.financeTillRateNone,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    : _RateValue(rate: rate),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Le taux **du dollar en francs en vigueur aujourd'hui**, ou `null`.
  ///
  /// ⚠️ **Pas de repli sur le plus ancien.** [ExchangeRates.at] l'offre pour le
  /// guichet, dont la tablette peut retarder sur le serveur et qui, sans taux,
  /// inventerait. Cet écran-ci est un écran de direction, et sa documentation
  /// tranche le cas : « l'écran de direction doit dire la vérité stricte —
  /// "aucun taux en vigueur" est une information juste ».
  ///
  /// ⚠️ **Le sens ne s'inverse pas.** La paire est lue telle qu'elle est
  /// stockée — `USD` de créance contre `CDF` reçus — et une école qui n'aurait
  /// que le sens contraire rend `null` plutôt qu'un taux retourné : l'inverse
  /// d'un taux arrondi n'est pas le taux inverse, et ce nombre s'imprime sur
  /// les tickets.
  static ExchangeRate? _dollarInFrancs(List<ExchangeRate> rates) =>
      ExchangeRates.at(
        rates,
        base: CurrencyCode.usd,
        quote: CurrencyCode.cdf,
        moment: DateTime.now(),
      );
}

/// « 1 $ = 2 850,00 FC ».
class _RateValue extends StatelessWidget {
  final ExchangeRate rate;

  const _RateValue({required this.rate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.financeTillRateValue(
      MoneyFormat.symbolOf(rate.base),
      rate.formatted(),
      MoneyFormat.symbolOf(rate.quote),
    );

    return Semantics(
      label: l10n.financeTillRateA11yLabel(text),
      child: ExcludeSemantics(
        child: Text(
          text,
          style: AppTextStyles.moneyTabular.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _RateMedallion extends StatelessWidget {
  final double size;

  const _RateMedallion({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.repeat_rounded,
        size: 16,
        color: AppColors.terreCuite,
      ),
    );
  }
}
