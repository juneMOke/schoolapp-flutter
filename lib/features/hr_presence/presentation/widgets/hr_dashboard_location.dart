import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';

/// La période du tableau de bord tenue dans l'adresse :
/// `?periode=week`, ou `?periode=custom&du=2026-10-09&au=2026-10-23`. F5 la
/// retrouve, un lien la partage, Précédent revient à la période d'avant.
///
/// « Ce mois », le défaut, laisse l'adresse nue ; la recherche n'y va pas.
class HrDashboardLocation extends StatelessWidget {
  static const periodParam = 'periode';
  static const fromParam = 'du';
  static const toParam = 'au';

  final HrPresenceDashboardState state;
  final HrPresenceDashboardCubit cubit;
  final Widget child;

  const HrDashboardLocation({
    super.key,
    required this.state,
    required this.cubit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final custom = state.period == DashboardPeriod.custom;
    final window = state.window;
    return LocationParamsSync(
      current: {
        periodParam: state.period == HrPresenceDashboardState.defaultPeriod
            ? null
            : state.period.name,
        fromParam: custom && window != null
            ? SchoolDayCalendar.dayOf(window.from)
            : null,
        toParam: custom && window != null
            ? SchoolDayCalendar.dayOf(window.to)
            : null,
      },
      onLocation: (values) => unawaited(
        cubit.applyLocation(
          period:
              DashboardPeriod.values
                  .where((p) => p.name == values[periodParam])
                  .firstOrNull ??
              HrPresenceDashboardState.defaultPeriod,
          range: _range(values[fromParam], values[toParam]),
        ),
      ),
      child: child,
    );
  }

  /// Des bornes lisibles, dans l'ordre, et que le serveur accepte ; sinon
  /// `null` — la période précise s'ouvre sur sa fenêtre par défaut.
  static DashboardWindow? _range(String? from, String? to) {
    if (from == null || to == null) return null;
    if (!SchoolDayCalendar.isDay(from) || !SchoolDayCalendar.isDay(to)) {
      return null;
    }
    var start = DateTime.parse(from);
    var end = DateTime.parse(to);
    // Du > Au : inversés, comme à la saisie (spec §1).
    if (start.isAfter(end)) (start, end) = (end, start);
    final window = DashboardWindow(from: start, to: end);
    return window.dayCount > DashboardWindow.maxDayCount ? null : window;
  }
}
