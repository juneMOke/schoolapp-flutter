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

  /// La période, les bornes et la devise lues dans l'adresse à l'ouverture
  /// (F5, lien) : elles priment sur la période mémorisée. `null` pour une
  /// adresse nue.
  final BoutiqueDashboardLocationApplied? location;

  const BoutiqueDashboardStarted({
    required this.academicYearId,
    this.yearStart,
    this.location,
  });

  @override
  List<Object?> get props => [academicYearId, yearStart, location];
}

/// L'adresse a changé (Précédent, Suivant, lien) : l'écran la rejoint.
///
/// [range] n'est lu que par la période précise — absent, elle s'ouvre sur la
/// journée. [currency] `null` : la première devise de la réponse.
class BoutiqueDashboardLocationApplied extends BoutiqueDashboardEvent {
  final DashboardPeriod period;
  final DashboardWindow? range;
  final String? currency;

  const BoutiqueDashboardLocationApplied({
    required this.period,
    this.range,
    this.currency,
  });

  @override
  List<Object?> get props => [period, range, currency];
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
