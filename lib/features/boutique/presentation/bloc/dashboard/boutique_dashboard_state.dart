part of 'boutique_dashboard_bloc.dart';

const Object _undefined = Object();

enum BoutiqueDashboardStatus { initial, loading, ready, failure }

class BoutiqueDashboardState extends Equatable {
  final BoutiqueDashboardStatus status;
  final String academicYearId;
  final DateTime? yearStart;
  final DashboardPeriod period;

  /// La fenêtre **demandée** — écrite dans l'en-tête dès le geste, avant la
  /// réponse. `null` avant le premier montage.
  final DashboardWindow? window;

  /// Les chiffres du serveur, **tickets provisoires ajoutés**.
  final BoutiqueStats? stats;

  /// Quand la photo affichée a été prise, si elle vient du cache.
  final DateTime? cachedAt;

  /// Les tickets du poste que le serveur ne connaît pas encore — gardés même
  /// quand le serveur échoue : l'encart reste visible au-dessus de l'erreur.
  final ProvisionalSales provisional;

  final Failure? failure;

  /// Vrai pendant qu'une nouvelle période se charge **par-dessus** des valeurs
  /// déjà affichées : elles restent visibles, atténuées, plutôt qu'un squelette
  /// plein écran qui ferait clignoter la page.
  final bool refreshing;

  /// La devise détaillée par la série et les familles.
  final String? selectedCurrency;

  const BoutiqueDashboardState({
    this.status = BoutiqueDashboardStatus.initial,
    this.academicYearId = '',
    this.yearStart,
    this.period = DashboardPeriod.defaultPeriod,
    this.window,
    this.stats,
    this.cachedAt,
    this.provisional = ProvisionalSales.none,
    this.failure,
    this.refreshing = false,
    this.selectedCurrency,
  });

  BoutiqueCurrencyStats? get selectedBlock => stats?.blockOf(selectedCurrency);

  /// Rien vendu sur la fenêtre, provisoires compris.
  bool get isEmpty => stats != null && !stats!.hasSales;

  /// Le delta a-t-il un sens ? Pas si la fenêtre précédente **chevauche** la
  /// rentrée : le serveur la borne à l'année, et quelques jours se
  /// compareraient à une semaine pleine.
  bool get isDeltaComparable {
    final start = yearStart;
    final counted = stats?.window;
    if (start == null || counted == null) return true;
    return !counted.previousFrom.isBefore(
      DateTime(start.year, start.month, start.day),
    );
  }

  BoutiqueDashboardState copyWith({
    BoutiqueDashboardStatus? status,
    String? academicYearId,
    Object? yearStart = _undefined,
    DashboardPeriod? period,
    DashboardWindow? window,
    Object? stats = _undefined,
    Object? cachedAt = _undefined,
    ProvisionalSales? provisional,
    Object? failure = _undefined,
    bool? refreshing,
    Object? selectedCurrency = _undefined,
  }) => BoutiqueDashboardState(
    status: status ?? this.status,
    academicYearId: academicYearId ?? this.academicYearId,
    yearStart: identical(yearStart, _undefined)
        ? this.yearStart
        : yearStart as DateTime?,
    period: period ?? this.period,
    window: window ?? this.window,
    stats: identical(stats, _undefined) ? this.stats : stats as BoutiqueStats?,
    cachedAt: identical(cachedAt, _undefined)
        ? this.cachedAt
        : cachedAt as DateTime?,
    provisional: provisional ?? this.provisional,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    refreshing: refreshing ?? this.refreshing,
    selectedCurrency: identical(selectedCurrency, _undefined)
        ? this.selectedCurrency
        : selectedCurrency as String?,
  );

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    yearStart,
    period,
    window,
    stats,
    cachedAt,
    provisional,
    failure,
    refreshing,
    selectedCurrency,
  ];
}
