import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_call_list_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/recouvrement_call_list_sheet.dart';
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

/// Ouvre l'**aperçu nominatif** d'un groupe visé.
///
/// Le clic sur une ligne de simulation ne produit plus de papier : il montre
/// d'abord **qui** est visé. La liste qui en sort se signe et circule — la faire
/// sortir d'un clic ferait produire un document que personne n'a lu, sur une
/// population qu'on n'a pas vérifiée. C'est aussi l'ordre que la spec pose.
///
/// L'aperçu et l'édition partagent la MÊME population, calculée une seule fois
/// ici : deux appels du prédicat à deux instants pourraient déjà diverger, et
/// l'écran ne doit pas montrer douze noms pour en imprimer treize.
Future<void> openCallListFor(
  BuildContext context,
  String? schoolLevelId,
  RecouvrementDashboardState dashboard, {
  required String groupLabel,
  required String criterionLabel,
}) async {
  final targeted = targetedLinesOf(context, schoolLevelId, dashboard);
  if (targeted == null || targeted.isEmpty) return;

  final callList = getIt<RecouvrementCallListCubit>();
  final relance = context.read<RelanceListCubit>();
  final query = dashboard.lastQuery;
  final simulation = context.read<RecouvrementSimulationCubit>().state;
  if (query == null || schoolLevelId == null) return;

  unawaited(
    callList.load(
      academicYearId: query.academicYearId,
      schoolLevelId: schoolLevelId,
      targeted: targeted,
    ),
  );

  await showDialog<void>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<RecouvrementCallListCubit>.value(value: callList),
        // Le cubit d'édition vient de la PAGE, pas de la modale : l'attente
        // qu'un 429 impose doit survivre à la fermeture, sinon rouvrir
        // l'aperçu réarmerait un bouton que le serveur vient de refuser.
        BlocProvider<RelanceListCubit>.value(value: relance),
      ],
      child: RecouvrementCallListSheet(
        groupLabel: groupLabel,
        criterionLabel: criterionLabel,
        onEmit: () => relance.emit_(
          scope: RelanceScope.schoolLevel(schoolLevelId),
          feeCodes: query.feeCodes,
          criterion: simulation.criterion,
          lines: targeted,
          thresholdInCents: simulation.threshold?.amountInCents,
          thresholdCurrency: simulation.threshold?.currency,
        ),
      ),
    ),
  );
  await callList.close();
}

/// Les lignes que la simulation vise **dans ce groupe**, ou `null` quand le
/// groupe n'est pas exploitable.
///
/// ⚠️ **Un groupe sans niveau n'est pas exploitable.** `scope.kind` du contrat
/// n'a que `CLASSROOM`, `SCHOOL_LEVEL`, `SCHOOL_LEVEL_GROUP` et `UNASSIGNED` —
/// et `UNASSIGNED` y désigne les élèves sans CLASSE, pas les créances sans
/// NIVEAU. Les confondre ferait titrer le papier « Non affectés » sur une
/// population qui n'est pas celle-là.
List<LocalRecoveryLine>? targetedLinesOf(
  BuildContext context,
  String? schoolLevelId,
  RecouvrementDashboardState dashboard,
) {
  if (schoolLevelId == null) return null;
  if (dashboard.lastQuery == null) return null;

  final simulation = context.read<RecouvrementSimulationCubit>().state;
  return RecouvrementSimulationProjector.targetsOf(
    [
      for (final line in context.read<RecouvrementDashboardBloc>().lines)
        if (line.schoolLevelId == schoolLevelId) line,
    ],
    criterion: simulation.criterion,
    threshold: simulation.threshold,
    rate: dollarInFrancs(context.read<ExchangeRatesCubit>().state.rates),
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
