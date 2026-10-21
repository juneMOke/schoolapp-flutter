import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/provisional_stats_merger.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/dashboard_period_preference.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_latest_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_provisional_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_stats_use_case.dart';

part 'boutique_dashboard_event.dart';
part 'boutique_dashboard_state.dart';

/// Le tableau de bord de la boutique : « combien a-t-elle vendu, et quoi ? »
///
/// Trois lectures par fenêtre — les chiffres du serveur, les tickets
/// provisoires du poste (ajoutés aux premiers), les dernières ventes locales.
/// La liste des élèves a son propre cubit : ses filtres et sa pagination ne
/// doivent pas démonter le reste de l'écran.
class BoutiqueDashboardBloc
    extends Bloc<BoutiqueDashboardEvent, BoutiqueDashboardState> {
  final GetBoutiqueStatsUseCase _getStats;
  final GetBoutiqueProvisionalSalesUseCase _getProvisional;
  final GetBoutiqueLatestSalesUseCase _getLatest;
  final DashboardPeriodPreference _preference;
  final DateTime Function() _now;

  /// Le numéro de la dernière lecture lancée. Une réponse plus ancienne — un
  /// « 7 jours » qui arrive après le « 30 jours » demandé ensuite — est jetée :
  /// l'écran marquerait une fenêtre et en afficherait une autre.
  int _ticket = 0;

  BoutiqueDashboardBloc({
    required GetBoutiqueStatsUseCase getStats,
    required GetBoutiqueProvisionalSalesUseCase getProvisional,
    required GetBoutiqueLatestSalesUseCase getLatest,
    required DashboardPeriodPreference preference,
    DateTime Function() now = DateTime.now,
  }) : _getStats = getStats,
       _getProvisional = getProvisional,
       _getLatest = getLatest,
       _preference = preference,
       _now = now,
       super(const BoutiqueDashboardState()) {
    on<BoutiqueDashboardStarted>(_onStarted);
    on<BoutiqueDashboardPeriodChanged>(_onPeriodChanged);
    on<BoutiqueDashboardRefreshRequested>(_onRefreshRequested);
    on<BoutiqueDashboardCurrencySelected>(_onCurrencySelected);
  }

  Future<void> _onStarted(
    BoutiqueDashboardStarted event,
    Emitter<BoutiqueDashboardState> emit,
  ) async {
    final period = await _preference.read() ?? DashboardPeriod.defaultPeriod;
    emit(
      state.copyWith(
        academicYearId: event.academicYearId,
        yearStart: event.yearStart,
        period: period,
      ),
    );
    await _load(emit, keepData: false);
  }

  Future<void> _onPeriodChanged(
    BoutiqueDashboardPeriodChanged event,
    Emitter<BoutiqueDashboardState> emit,
  ) async {
    if (event.period == state.period && state.window != null) return;
    // La période est posée AVANT la lecture : le sélecteur suit le doigt.
    emit(state.copyWith(period: event.period));
    await _preference.write(event.period);
    await _load(emit, keepData: true);
  }

  Future<void> _onRefreshRequested(
    BoutiqueDashboardRefreshRequested event,
    Emitter<BoutiqueDashboardState> emit,
  ) => _load(emit, keepData: true);

  void _onCurrencySelected(
    BoutiqueDashboardCurrencySelected event,
    Emitter<BoutiqueDashboardState> emit,
  ) {
    if (state.stats?.blockOf(event.currency) == null) return;
    emit(state.copyWith(selectedCurrency: event.currency));
  }

  Future<void> _load(
    Emitter<BoutiqueDashboardState> emit, {
    required bool keepData,
  }) async {
    final ticket = ++_ticket;
    final window = state.period.windowAt(_now());
    final hasData = keepData && state.stats != null;
    emit(
      state.copyWith(
        window: window,
        status: hasData ? state.status : BoutiqueDashboardStatus.loading,
        refreshing: hasData,
      ),
    );

    final yearId = state.academicYearId;
    final (statsResult, latestResult) = await (
      _getStats(academicYearId: yearId, window: window),
      _getLatest(academicYearId: yearId, window: window),
    ).wait;
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
    final latest = latestResult.fold<List<SaleHistoryEntry>?>(
      (_) => null,
      (sales) => sales,
    );

    statsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: BoutiqueDashboardStatus.failure,
          failure: failure,
          stats: null,
          cachedAt: null,
          provisional: provisional,
          latestSales: latest,
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
            latestSales: latest,
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
