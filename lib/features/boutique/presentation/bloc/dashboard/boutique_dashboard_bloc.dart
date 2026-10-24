import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/provisional_stats_merger.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/dashboard_period_preference.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_provisional_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_stats_use_case.dart';

part 'boutique_dashboard_event.dart';
part 'boutique_dashboard_state.dart';

/// Le tableau de bord de la boutique : « combien a-t-elle vendu, et quoi ? »
///
/// Deux lectures par fenêtre — les chiffres du serveur, et les tickets
/// provisoires du poste, ajoutés aux premiers. La liste des élèves et celle
/// des ventes ont chacune leur cubit : leurs filtres et leur pagination ne
/// doivent pas démonter le reste de l'écran.
class BoutiqueDashboardBloc
    extends Bloc<BoutiqueDashboardEvent, BoutiqueDashboardState> {
  final GetBoutiqueStatsUseCase _getStats;
  final GetBoutiqueProvisionalSalesUseCase _getProvisional;
  final DashboardPeriodPreference _preference;
  final DateTime Function() _now;

  /// Le numéro de la dernière lecture lancée. Une réponse plus ancienne — une
  /// « semaine » qui arrive après le « mois » demandé ensuite — est jetée :
  /// l'écran marquerait une fenêtre et en afficherait une autre.
  int _ticket = 0;

  BoutiqueDashboardBloc({
    required GetBoutiqueStatsUseCase getStats,
    required GetBoutiqueProvisionalSalesUseCase getProvisional,
    required DashboardPeriodPreference preference,
    DateTime Function() now = DateTime.now,
  }) : _getStats = getStats,
       _getProvisional = getProvisional,
       _preference = preference,
       _now = now,
       super(const BoutiqueDashboardState()) {
    on<BoutiqueDashboardStarted>(_onStarted);
    on<BoutiqueDashboardPeriodChanged>(_onPeriodChanged);
    on<BoutiqueDashboardCustomRangeChanged>(_onCustomRangeChanged);
    on<BoutiqueDashboardRefreshRequested>(_onRefreshRequested);
    on<BoutiqueDashboardCurrencySelected>(_onCurrencySelected);
  }

  Future<void> _onStarted(
    BoutiqueDashboardStarted event,
    Emitter<BoutiqueDashboardState> emit,
  ) async {
    // Idempotent : le gate d'année redemande le contexte au montage et remonte
    // la vue, qui redémarrerait l'écran pour la même année.
    if (event.academicYearId == state.academicYearId &&
        state.status != BoutiqueDashboardStatus.initial) {
      return;
    }
    // L'année est posée AVANT la lecture de la préférence : un second
    // démarrage arrivé pendant cet `await` se reconnaît et s'arrête.
    emit(
      state.copyWith(
        academicYearId: event.academicYearId,
        yearStart: event.yearStart,
        status: BoutiqueDashboardStatus.loading,
      ),
    );
    final period = await _preference.read() ?? DashboardPeriod.defaultPeriod;
    emit(state.copyWith(period: period));
    await _load(emit, window: _presetWindow(period), keepData: false);
  }

  Future<void> _onPeriodChanged(
    BoutiqueDashboardPeriodChanged event,
    Emitter<BoutiqueDashboardState> emit,
  ) async {
    // Avant la première fenêtre, la période mémorisée est encore en lecture :
    // un geste arrivé là serait écrasé par elle.
    if (state.window == null || event.period == state.period) return;
    // La période est posée AVANT la lecture : le sélecteur suit le doigt.
    emit(state.copyWith(period: event.period));
    if (event.period == DashboardPeriod.custom) {
      // Par défaut, la journée d'aujourd'hui — comme aux inscriptions : une
      // fenêtre valide et lisible, que l'utilisateur élargit ensuite. Ouvrir
      // sur deux champs vides laisserait l'écran sans chiffres sans dire
      // pourquoi.
      final today = SchoolTime.today(_now());
      await _load(
        emit,
        window: DashboardWindow(from: today, to: today),
        keepData: true,
      );
      return;
    }
    await _preference.write(event.period);
    await _load(emit, window: _presetWindow(event.period), keepData: true);
  }

  Future<void> _onCustomRangeChanged(
    BoutiqueDashboardCustomRangeChanged event,
    Emitter<BoutiqueDashboardState> emit,
  ) async {
    if (state.window == null) return;
    if (state.period == DashboardPeriod.custom &&
        event.window == state.window) {
      return;
    }
    emit(state.copyWith(period: DashboardPeriod.custom));
    await _load(emit, window: event.window, keepData: true);
  }

  /// La période précise rejoue **ses** bornes ; les autres recalculent la
  /// leur — minuit passé, « aujourd'hui » a changé de jour.
  Future<void> _onRefreshRequested(
    BoutiqueDashboardRefreshRequested event,
    Emitter<BoutiqueDashboardState> emit,
  ) => _load(
    emit,
    window: state.period == DashboardPeriod.custom && state.window != null
        ? state.window!
        : _presetWindow(state.period),
    keepData: true,
  );

  /// La fenêtre d'une période calculée. Une période précise sans bornes — ce
  /// qui n'arrive qu'à une préférence corrompue — retombe sur le défaut.
  DashboardWindow _presetWindow(DashboardPeriod period) =>
      (period == DashboardPeriod.custom
              ? DashboardPeriod.defaultPeriod
              : period)
          .windowAt(_now(), yearStart: state.yearStart);

  void _onCurrencySelected(
    BoutiqueDashboardCurrencySelected event,
    Emitter<BoutiqueDashboardState> emit,
  ) {
    if (state.stats?.blockOf(event.currency) == null) return;
    emit(state.copyWith(selectedCurrency: event.currency));
  }

  Future<void> _load(
    Emitter<BoutiqueDashboardState> emit, {
    required DashboardWindow window,
    required bool keepData,
  }) async {
    final ticket = ++_ticket;
    final hasData = keepData && state.stats != null;
    emit(
      state.copyWith(
        window: window,
        status: hasData ? state.status : BoutiqueDashboardStatus.loading,
        refreshing: hasData,
      ),
    );

    final yearId = state.academicYearId;
    final statsResult = await _getStats(academicYearId: yearId, window: window);
    if (ticket != _ticket) return;

    final snapshot = statsResult.fold((_) => null, (value) => value);
    // Les provisoires de LA fenêtre comptée : une photo de cache d'hier ne
    // doit pas absorber les tickets d'aujourd'hui, ni l'inverse.
    final provisionalResult = await _getProvisional(
      academicYearId: yearId,
      window: snapshot?.stats.window ?? window,
    );
    if (ticket != _ticket) return;
    final provisional = provisionalResult.getOrElse(
      () => ProvisionalSales.none,
    );

    statsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: BoutiqueDashboardStatus.failure,
          failure: failure,
          stats: null,
          cachedAt: null,
          provisional: provisional,
          refreshing: false,
        ),
      ),
      (snapshot) {
        final stats = ProvisionalStatsMerger.merge(snapshot.stats, provisional);
        emit(
          state.copyWith(
            status: BoutiqueDashboardStatus.ready,
            failure: null,
            stats: stats,
            cachedAt: snapshot.cachedAt,
            provisional: provisional,
            refreshing: false,
            selectedCurrency: _resolveCurrency(state.selectedCurrency, stats),
          ),
        );
      },
    );
  }

  /// La devise examinée survit au changement de période — sauf si la nouvelle
  /// réponse ne la porte plus : elle est alors réarbitrée plutôt que laissée à
  /// pointer dans le vide.
  static String? _resolveCurrency(String? current, BoutiqueStats stats) {
    if (stats.blockOf(current) != null) return current;
    return stats.byCurrency.isEmpty ? null : stats.byCurrency.first.currency;
  }
}
