import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

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
/// qu'un reçu d'hier ne s'aligne pas dessus — et il porte la porte vers
/// Réglages, seul endroit où ce nombre se change.
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

  /// Médaillon de 30 dp, rayon 9 — la maquette les conserve même quand le lien
  /// passe à la ligne, donc ils ne sont pas dans le [Wrap].
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

        final rates = _inForce(state.rates);

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
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppDimensions.spacingM,
                  runSpacing: AppDimensions.spacingXS,
                  children: [
                    if (rates.isEmpty)
                      Semantics(
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
                    else
                      for (final rate in rates) _RateValue(rate: rate),
                    const _EditRateLink(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Les taux **en vigueur aujourd'hui**, un par paire, l'identité exclue.
  ///
  /// ⚠️ **Pas de repli sur le plus ancien.** [ExchangeRates.at] l'offre pour le
  /// guichet, dont la tablette peut retarder sur le serveur et qui, sans taux,
  /// inventerait. Cet écran-ci est un écran de direction, et sa documentation
  /// tranche le cas : « l'écran de direction doit dire la vérité stricte —
  /// "aucun taux en vigueur" est une information juste ».
  ///
  /// L'identité (`1 USD = 1 USD`) est écartée : la table en contient par
  /// construction — « il n'y a pas de "pas de taux" dans la table, il y a un
  /// taux de 1 » — et l'afficher remplirait le bandeau d'évidences.
  ///
  /// Toutes les paires en vigueur sont rendues, et non une choisie au hasard :
  /// l'école n'en configure qu'une en pratique, mais si elle en pose deux, en
  /// taire une serait le genre de silence que cet écran refuse partout
  /// ailleurs. Le [Wrap] les prend.
  static List<ExchangeRate> _inForce(List<ExchangeRate> rates) {
    final now = DateTime.now();
    final pairs = <String>{
      for (final rate in rates) '${rate.base}>${rate.quote}',
    };

    final inForce = <ExchangeRate>[];
    for (final pair in pairs.toList()..sort()) {
      final parts = pair.split('>');
      final rate = ExchangeRates.at(
        rates,
        base: parts.first,
        quote: parts.last,
        moment: now,
      );
      // ⚠️ **Le seul filtre d'identité, et il est ici.** Le doubler à la
      // collecte des paires ne retirait rien : une paire dont les deux devises
      // diffèrent n'est jamais l'identité, et une paire USD>USD y serait
      // écartée deux fois. Un sabotage l'a montré — la suite restait verte
      // sans lui, ce qui en faisait un garde-fou que rien ne défendait.
      if (rate != null && !rate.isIdentity) inForce.add(rate);
    }
    return inForce;
  }
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

/// **La seule sortie de cet écran en lecture seule** — et elle est gardée.
///
/// ⚠️ Configuration ▸ Réglages exige `school.provisioning.write`, que la caisse
/// (`finance.stats.read`) ne porte pas. Sans garde, un caissier légitime
/// verrait un lien vers une page qui lui est fermée : exactement la promesse
/// d'un geste qui n'existe pas que le reste de l'écran refuse — les lignes de
/// poste n'ont pas d'`onTap`, les cartes de lecture n'ont pas de bouton.
///
/// [PermissionGate] **masque** plutôt qu'il ne grise : un lien absent dit « pas
/// vous », un lien estompé dirait « pas maintenant ». C'est le second qui
/// serait faux ici.
class _EditRateLink extends StatelessWidget {
  const _EditRateLink();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PermissionGate(
      requires: const [Perm.schoolProvisioningWrite],
      child: InkWell(
        onTap: () => _openSettings(context),
        borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXS,
            vertical: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.financeTillRateEdit,
                style: AppTextStyles.action.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.bleuArdoise,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rejoint Réglages **dans la coquille**, comme la maquette
  /// (`onNavigate('configuration','cfg-reglages')`).
  ///
  /// Le paramètre `subMenuId` de `/home` est le chemin que l'application se
  /// donne déjà pour ce geste (cf. `EnrollmentNavigationHelper`) : il vaut
  /// depuis la page hors coquille comme depuis la coquille, là où un
  /// `go('/configuration/settings')` sortirait le lecteur de sa barre latérale.
  static void _openSettings(BuildContext context) {
    context.goNamed(
      AppRoutesNames.home,
      queryParameters: {'subMenuId': MenuConstants.configurationSchoolId},
    );
  }
}
