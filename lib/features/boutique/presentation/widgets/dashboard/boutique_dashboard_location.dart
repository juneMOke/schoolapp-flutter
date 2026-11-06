import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_cubit.dart';

/// Le tableau de bord de la boutique tenu dans son adresse :
/// `?periode=custom&du=2026-10-01&au=2026-10-15&devise=USD`, puis les
/// filtres des deux listes (`ventes-par`, `ventes-type`, `ventes-classe`,
/// `ventes-page`, `eleves-article`, `eleves-classe`). F5 rouvre le même
/// écran — donc la même requête, et le même PDF.
///
/// Les valeurs par défaut laissent l'adresse nue : « Cette semaine », la
/// première devise, la première page. La recherche n'y va pas : chaque
/// frappe serait une entrée d'historique.
class BoutiqueDashboardLocation extends StatelessWidget {
  static const periodParam = 'periode';
  static const fromParam = 'du';
  static const toParam = 'au';
  static const currencyParam = 'devise';
  static const salesModeParam = 'ventes-par';
  static const salesFamilyParam = 'ventes-type';
  static const salesClassParam = 'ventes-classe';
  static const salesPageParam = 'ventes-page';
  static const beneficiaryArticleParam = 'eleves-article';
  static const beneficiaryClassParam = 'eleves-classe';

  /// `ventes-par=classe` : la liste des ventes filtrée par classe.
  static const classroomModeValue = 'classe';

  static const keys = [
    periodParam,
    fromParam,
    toParam,
    currencyParam,
    salesModeParam,
    salesFamilyParam,
    salesClassParam,
    salesPageParam,
    beneficiaryArticleParam,
    beneficiaryClassParam,
  ];

  final Widget child;

  const BoutiqueDashboardLocation({super.key, required this.child});

  /// Lit l'adresse d'ouverture et la pose sur les trois états, AVANT le
  /// premier chargement : sans cela, l'écran lirait d'abord sa période
  /// mémorisée, puis celle de l'adresse. Rend l'événement à joindre au
  /// démarrage, `null` pour une adresse nue (ou sans routeur).
  static BoutiqueDashboardLocationApplied? readOpening(BuildContext context) {
    final router = LocationQuery.ownedBy(context);
    if (router == null) return null;
    final values = {
      for (final key in keys) key: LocationQuery.read(router, key),
    };
    if (values.values.every((value) => value == null)) return null;
    _applyToLists(context, values);
    return dashboardOf(values);
  }

  /// La période, les bornes et la devise d'une adresse.
  static BoutiqueDashboardLocationApplied dashboardOf(
    Map<String, String?> values,
  ) => BoutiqueDashboardLocationApplied(
    period:
        DashboardPeriod.values
            .where((p) => p.name == values[periodParam])
            .firstOrNull ??
        DashboardPeriod.defaultPeriod,
    range: _range(values[fromParam], values[toParam]),
    currency: values[currencyParam],
  );

  static void _applyToLists(BuildContext context, Map<String, String?> values) {
    final classroom = values[salesModeParam] == classroomModeValue;
    final page = int.tryParse(values[salesPageParam] ?? '');
    unawaited(
      context.read<BoutiqueSalesCubit>().applyLocation(
        mode: classroom ? SalesFilterMode.classroom : SalesFilterMode.family,
        family: ArticleFamily.values
            .where((f) => f.name == values[salesFamilyParam])
            .firstOrNull,
        classId: values[salesClassParam],
        page: page == null || page < 1 ? 0 : page - 1,
      ),
    );
    unawaited(
      context.read<BoutiqueBeneficiariesCubit>().applyLocation(
        articleId: values[beneficiaryArticleParam],
        classId: values[beneficiaryClassParam],
      ),
    );
  }

  /// Des bornes lisibles, dans l'ordre, et que le serveur accepte ; sinon
  /// `null` — la période précise s'ouvre sur la journée.
  static DashboardWindow? _range(String? from, String? to) {
    if (from == null || to == null) return null;
    if (!SchoolDayCalendar.isDay(from) || !SchoolDayCalendar.isDay(to)) {
      return null;
    }
    var start = DateTime.parse(from);
    var end = DateTime.parse(to);
    if (start.isAfter(end)) (start, end) = (end, start);
    final window = DashboardWindow(from: start, to: end);
    return window.dayCount > DashboardWindow.maxDayCount ? null : window;
  }

  /// L'adresse porte-t-elle déjà la période de [state] ? Vrai quand la
  /// fenêtre vient de l'adresse (Précédent, Suivant, lien) : la page de la
  /// liste, lue dans la même adresse, reste. Faux après un geste — l'adresse
  /// ne le suit qu'à l'image suivante — et la liste repart de la page 1.
  static bool addressHolds(BuildContext context, BoutiqueDashboardState state) {
    final router = LocationQuery.ownedBy(context);
    if (router == null) return false;
    final (period, from, to, _, _) = _dashboardValues(state);
    return LocationQuery.read(router, periodParam) == period &&
        LocationQuery.read(router, fromParam) == from &&
        LocationQuery.read(router, toParam) == to;
  }

  static (String?, String?, String?, String?, bool) _dashboardValues(
    BoutiqueDashboardState state,
  ) {
    final custom = state.period == DashboardPeriod.custom;
    final window = state.window;
    final currencies = state.stats?.byCurrency;
    final selected = state.selectedCurrency;
    return (
      state.period == DashboardPeriod.defaultPeriod ? null : state.period.name,
      custom && window != null ? SchoolDayCalendar.dayOf(window.from) : null,
      custom && window != null ? SchoolDayCalendar.dayOf(window.to) : null,
      currencies != null &&
              currencies.isNotEmpty &&
              currencies.first.currency == selected
          ? null
          : selected,
      state.periodFromPreference,
    );
  }

  static (String?, String?, String?, String?, bool) _salesValues(
    BoutiqueSalesState state,
  ) {
    final classroom = state.mode == SalesFilterMode.classroom;
    return (
      classroom ? classroomModeValue : null,
      classroom ? null : state.family?.name,
      classroom ? state.classId : null,
      state.pageIndex == 0 ? null : '${state.pageIndex + 1}',
      state.pageCorrected,
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        BoutiqueDashboardBloc,
        BoutiqueDashboardState,
        (String?, String?, String?, String?, bool)
      >(
        selector: _dashboardValues,
        builder: (context, dashboard) =>
            BlocSelector<
              BoutiqueSalesCubit,
              BoutiqueSalesState,
              (String?, String?, String?, String?, bool)
            >(
              selector: _salesValues,
              builder: (context, sales) =>
                  BlocSelector<
                    BoutiqueBeneficiariesCubit,
                    BoutiqueBeneficiariesState,
                    (String?, String?)
                  >(
                    selector: (state) => (state.articleId, state.classId),
                    builder: (context, beneficiaries) => LocationParamsSync(
                      current: {
                        periodParam: dashboard.$1,
                        fromParam: dashboard.$2,
                        toParam: dashboard.$3,
                        currencyParam: dashboard.$4,
                        salesModeParam: sales.$1,
                        salesFamilyParam: sales.$2,
                        salesClassParam: sales.$3,
                        salesPageParam: sales.$4,
                        beneficiaryArticleParam: beneficiaries.$1,
                        beneficiaryClassParam: beneficiaries.$2,
                      },
                      quietKeys: {
                        if (dashboard.$5) periodParam,
                        if (sales.$5) salesPageParam,
                      },
                      onLocation: (values) {
                        context.read<BoutiqueDashboardBloc>().add(
                          dashboardOf(values),
                        );
                        _applyToLists(context, values);
                      },
                      child: child,
                    ),
                  ),
            ),
      );
}
