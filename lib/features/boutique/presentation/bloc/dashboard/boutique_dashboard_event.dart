part of 'boutique_dashboard_bloc.dart';

sealed class BoutiqueDashboardEvent extends Equatable {
  const BoutiqueDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Premier montage : l'année est un paramètre, résolue par l'écran.
class BoutiqueDashboardStarted extends BoutiqueDashboardEvent {
  final String academicYearId;

  /// L'ouverture de l'année, si l'année la dit : une fenêtre précédente qui la
  /// précède ne se compare pas (cf. [BoutiqueDashboardState.isDeltaComparable]).
  final DateTime? yearStart;

  const BoutiqueDashboardStarted({
    required this.academicYearId,
    this.yearStart,
  });

  @override
  List<Object?> get props => [academicYearId, yearStart];
}

class BoutiqueDashboardPeriodChanged extends BoutiqueDashboardEvent {
  final DashboardPeriod period;

  const BoutiqueDashboardPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

/// Pose les bornes de la période précise — et bascule sur elle.
///
/// La fenêtre arrive **complète et dans l'ordre** : l'écran ne laisse composer
/// ni une borne vide ni une plage à l'envers.
class BoutiqueDashboardCustomRangeChanged extends BoutiqueDashboardEvent {
  final DashboardWindow window;

  const BoutiqueDashboardCustomRangeChanged(this.window);

  @override
  List<Object?> get props => [window];
}

/// Rejoue la période **retenue** — après une coupure, ou au retour d'une fiche.
class BoutiqueDashboardRefreshRequested extends BoutiqueDashboardEvent {
  const BoutiqueDashboardRefreshRequested();
}

/// Change la devise détaillée **sans rappeler le serveur**.
class BoutiqueDashboardCurrencySelected extends BoutiqueDashboardEvent {
  final String currency;

  const BoutiqueDashboardCurrencySelected(this.currency);

  @override
  List<Object?> get props => [currency];
}
