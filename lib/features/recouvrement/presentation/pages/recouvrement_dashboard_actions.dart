import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les deux gestes qui **sortent** du tableau de bord : ouvrir l'écran
/// nominatif, et éditer la liste de relance d'un groupe.
///
/// Ils vivent ici et non dans la page parce qu'ils ne dessinent rien : ils
/// lisent trois blocs, appliquent la règle de ciblage et partent ailleurs. La
/// page, elle, n'a qu'à les appeler — et redescend sous la cible de longueur
/// que le projet se donne.

/// Ouvre l'écran nominatif, **vierge**.
///
/// ⚠️ On ne lui passe PAS le frais. `FeeControlIntent` exige un cycle et un
/// niveau, et cette lecture-ci parle de toute l'école : il n'y en a aucun à
/// donner. Passer un `extra` d'une autre forme serait pire que rien —
/// `fromRouteExtra` le rendrait `null` sans un mot, et l'écran s'ouvrirait
/// vierge en laissant croire qu'il porte le frais désigné.
///
/// L'utilisateur re-choisit donc son frais là-bas. C'est un clic de plus,
/// assumé : le rendre implicite demanderait de rendre le périmètre facultatif
/// dans l'intention, ce qui touche l'écran voisin.
void openRecouvrementControl(BuildContext context) {
  context.push(AppRoutesNames.recouvrementControl);
}

/// Édite la liste nominative d'un groupe — **la seule sortie matérielle de
/// l'écran**, et son seul appel réseau.
///
/// Les lignes envoyées sont celles que la simulation vise **dans ce groupe**,
/// et elles viennent du registre local : lui seul voit les encaissements non
/// encore remontés. Le serveur les imprime, il ne les redérive pas.
void emitRelanceListFor(
  BuildContext context,
  String? schoolLevelId,
  RecouvrementDashboardState dashboard,
) {
  // ⚠️ **Un groupe sans niveau n'est pas éditable.** `scope.kind` du contrat
  // n'a que `CLASSROOM`, `SCHOOL_LEVEL`, `SCHOOL_LEVEL_GROUP` et
  // `UNASSIGNED` — et `UNASSIGNED` y désigne les élèves sans CLASSE, pas les
  // créances sans NIVEAU. Les confondre ferait titrer le papier « Non
  // affectés » sur une population qui n'est pas celle-là. Le dépliage refuse
  // déjà ce groupe pour une raison voisine ; l'édition le refuse aussi,
  // plutôt que d'imprimer un titre faux. À rouvrir avec le back si le besoin
  // se présente.
  if (schoolLevelId == null) return;

  final simulation = context.read<RecouvrementSimulationCubit>().state;
  final lines = context.read<RecouvrementDashboardBloc>().lines;
  final query = dashboard.lastQuery;
  if (query == null) return;

  // Le même filtre que la simulation, borné au groupe : ce sont les élèves
  // que l'écran vient d'afficher comme visés, pas une seconde population.
  final targeted = RecouvrementSimulationProjector.targetsOf(
    [
      for (final line in lines)
        if (line.schoolLevelId == schoolLevelId) line,
    ],
    criterion: simulation.criterion,
    threshold: simulation.threshold,
    rate: dollarInFrancs(context.read<ExchangeRatesCubit>().state.rates),
  );
  if (targeted.isEmpty) return;

  context.read<RelanceListCubit>().emit_(
    scope: RelanceScope.schoolLevel(schoolLevelId),
    feeCodes: query.feeCodes,
    criterion: simulation.criterion,
    lines: targeted,
    thresholdInCents: simulation.threshold?.amountInCents,
    thresholdCurrency: simulation.threshold?.currency,
  );
}

/// Le taux dollar → franc en vigueur, ou `null` si l'école n'en a posé aucun.
///
/// Le sens contraire rend `null` plutôt qu'un taux retourné : l'inverse d'un
/// taux arrondi n'est pas le taux inverse, et ce nombre sert des arbitrages.
ExchangeRate? dollarInFrancs(List<ExchangeRate> rates) => ExchangeRates.at(
  rates,
  base: CurrencyCode.usd,
  quote: CurrencyCode.cdf,
  moment: DateTime.now(),
);
