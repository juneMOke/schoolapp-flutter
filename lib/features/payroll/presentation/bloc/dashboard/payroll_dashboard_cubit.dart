import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

export 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_state.dart';

/// RH · Paie ▸ Tableau de bord, **lu au serveur** (P9) : l'écran entier sur
/// une seule requête, que le PDF reprend à l'identique.
///
/// - La file de la paie part **avant** la requête : l'écran voit les derniers
///   versements saisis sur la tablette.
/// - Changer de mois repasse par le squelette ; un filtre, une recherche ou
///   F5 gardent l'écran affiché jusqu'à la réponse, et un échec ne l'efface
///   pas.
/// - La recherche attend la fin de la frappe ([debounce]).
class PayrollDashboardCubit extends Cubit<PayrollDashboardState> {
  static const defaultDebounce = Duration(milliseconds: 300);

  final GetPayrollDashboardUseCase _read;
  final FetchPayslipUseCase _documents;
  final StaffSyncSignals _signals;

  /// Le filtre et la recherche de la requête qui a rempli l'écran : le PDF
  /// part sur eux, pas sur une frappe pas encore envoyée.
  ({PayrollDashboardFilter filter, String search})? _shown;
  final Duration debounce;
  Timer? _timer;

  /// Le numéro de la dernière lecture : une réponse dépassée est jetée.
  int _ticket = 0;

  PayrollDashboardCubit({
    required GetPayrollDashboardUseCase read,
    required FetchPayslipUseCase documents,
    required StaffSyncSignals signals,
    DateTime Function() now = DateTime.now,
    this.debounce = defaultDebounce,
  }) : _read = read,
       _documents = documents,
       _signals = signals,
       super(
         PayrollDashboardState(
           month: PayrollMonth.of(now()),
           currentMonth: PayrollMonth.of(now()),
         ),
       );

  Future<void> load() => _load(skeleton: state.dashboard == null, flush: true);

  /// F5, « Réessayer » : pousse la file, puis relit sans squelette.
  Future<void> refresh() =>
      _load(skeleton: state.dashboard == null, flush: true);

  /// Le mois d'une pastille, d'une flèche ou de l'adresse (`?mois=`) ;
  /// absent ou illisible : le mois en cours ; jamais au-delà de lui.
  Future<void> showMonth(String? month) async {
    var wanted = PayrollMonth.parse(month) ?? state.currentMonth;
    if (wanted.compareTo(state.currentMonth) > 0) wanted = state.currentMonth;
    if (wanted == state.month && state.dashboard != null) return;
    emit(state.copyWith(month: wanted));
    await _load(skeleton: true, flush: true);
  }

  /// L'adresse a changé (F5, Précédent, lien) : un seul rechargement pour le
  /// mois et le filtre lus.
  Future<void> applyLocation({
    required String? month,
    required PayrollDashboardFilter filter,
  }) async {
    var wanted = PayrollMonth.parse(month) ?? state.currentMonth;
    if (wanted.compareTo(state.currentMonth) > 0) wanted = state.currentMonth;
    if (wanted != state.month) {
      emit(state.copyWith(month: wanted, filter: filter));
      await _load(skeleton: true, flush: true);
    } else {
      await setFilter(filter);
    }
  }

  Future<void> stepMonth(int direction) =>
      showMonth(PayrollMonth.add(state.month, direction));

  Future<void> setFilter(PayrollDashboardFilter filter) async {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
    await _load(skeleton: false);
  }

  void setSearch(String text) {
    if (text == state.search) return;
    emit(state.copyWith(search: text));
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_load(skeleton: false)));
  }

  Future<void> clearRowFilters() async {
    _timer?.cancel();
    emit(state.copyWith(filter: PayrollDashboardFilter.all, search: ''));
    await _load(skeleton: false);
  }

  /// Le PDF « Ce que chaque salarié perçoit » sur les paramètres mêmes de
  /// l'écran affiché (règle n° 14).
  Future<Either<Failure, Uint8List>> pdf() {
    final shown = _shown;
    final query = shown?.search.trim() ?? '';
    return _documents.dashboard(
      state.dashboard?.month ?? state.month,
      filter: (shown?.filter ?? PayrollDashboardFilter.all).wire,
      query: query.isEmpty ? null : query,
    );
  }

  void selectCurrency(String currency) =>
      emit(state.copyWith(currency: () => currency));

  /// [flush] : pousser d'abord la file d'envoi — au chargement, à F5, au
  /// changement de mois ; pas à chaque filtre ni à chaque frappe, qui
  /// attendraient un envoi de toute la file.
  Future<void> _load({required bool skeleton, bool flush = false}) async {
    final ticket = ++_ticket;
    final shown = skeleton ? null : state.dashboard;
    emit(
      state.copyWith(
        load: shown == null ? PayrollDashboardLoad.loading : state.load,
        dashboard: skeleton ? () => null : null,
        refreshing: shown != null,
      ),
    );
    if (flush) {
      await _signals.flush();
      if (isClosed || ticket != _ticket) return;
    }
    final asked = (filter: state.filter, search: state.search);
    final result = await _read(
      state.month,
      filter: asked.filter,
      query: asked.search.trim().isEmpty ? null : asked.search.trim(),
    );
    if (isClosed || ticket != _ticket) return;
    if (result.isRight()) _shown = asked;
    result.fold(
      (failure) {
        final type = EteeloErrorType.fromFailure(failure);
        // Sans écran, ou session perdue / droit retiré : l'erreur en place,
        // dans son anatomie (règle n° 10).
        if (shown == null ||
            type == EteeloErrorType.unauthorized ||
            type == EteeloErrorType.forbidden) {
          emit(
            state.copyWith(
              load: PayrollDashboardLoad.failure,
              failure: () => failure,
              refreshing: false,
            ),
          );
          return;
        }
        // Une relecture qui échoue garde l'écran — et revient au filtre et à
        // la recherche qu'il montre, pour que puce, tableau et PDF disent la
        // même chose ; l'échec se dit une fois.
        final kept = _shown;
        emit(
          state.copyWith(
            refreshing: false,
            filter: kept?.filter,
            search: kept?.search,
            refreshFailure: () => failure,
            refreshFailureSeq: state.refreshFailureSeq + 1,
          ),
        );
      },
      (dashboard) => emit(
        state.copyWith(
          load: PayrollDashboardLoad.ready,
          dashboard: () => dashboard,
          failure: () => null,
          refreshing: false,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
