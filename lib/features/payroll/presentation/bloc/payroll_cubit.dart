import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_commands.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

/// La paie : lecture locale, livre du mois composé ici, filtres en mémoire,
/// gestes en file d'envoi. Relit la tablette après un geste, ou quand un pull
/// ou un flush la périme.
class PayrollCubit extends Cubit<PayrollState> {
  final LoadPayrollUseCase _load;
  final StaffSyncSignals _signals;
  final PayrollCommands commands;
  final DateTime Function() _now;
  void Function()? _unwatch;
  int _seq = 0;

  PayrollCubit({
    required LoadPayrollUseCase load,
    required StaffSyncSignals signals,
    required this.commands,
    DateTime Function() now = DateTime.now,
  }) : _load = load,
       _signals = signals,
       _now = now,
       super(PayrollState.initial(StaffWorkCalendar.dayOf(now())));

  Future<void> load() async {
    emit(state.copyWith(load: PayrollLoad.loading, clearFailure: true));
    _unwatch ??= _signals.watch(() => unawaited(refresh()));
    await _read(loading: true);
    if (isClosed) return;
    unawaited(_signals.pull());
  }

  /// Relecture silencieuse : jamais de squelette, un échec garde l'écran.
  Future<void> refresh() => _read(loading: false);

  /// « Synchroniser puis revoir » : tire les flux, puis relit.
  Future<void> syncAndRefresh() async {
    await _signals.pull();
    await refresh();
  }

  Future<void> _read({required bool loading}) async {
    if (isClosed) return;
    final result = await _load();
    if (isClosed) return;
    result.fold(
      (failure) {
        if (loading) {
          emit(state.copyWith(load: PayrollLoad.failure, failure: failure));
        }
      },
      (snapshot) => emit(
        state.copyWith(
          load: PayrollLoad.ready,
          snapshot: snapshot,
          today: StaffWorkCalendar.dayOf(_now()),
          view: PayrollLedger.monthView(snapshot, state.month),
          clearFailure: true,
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void setTab(PayrollTab tab) {
    if (tab != state.tab) emit(state.copyWith(tab: tab));
  }

  /// Le mois précédent ou suivant ; jamais au-delà du mois en cours, ni
  /// avant le premier contrat de l'école.
  void stepMonth(int direction) {
    if (direction < 0 && !state.canStepBack) return;
    final month = PayrollMonth.add(state.month, direction);
    if (month.compareTo(state.currentMonth) > 0) return;
    _openMonth(month);
  }

  void goCurrentMonth() => _openMonth(state.currentMonth);

  /// Un mois de l'historique ouvre son livre.
  void openMonth(String month) {
    _openMonth(month);
    setTab(PayrollTab.ledger);
  }

  void _openMonth(String month) {
    if (month == state.month) return;
    emit(
      state.copyWith(
        month: month,
        view: PayrollLedger.monthView(state.snapshot, month),
        payslipMemberId: () => null,
      ),
    );
  }

  /// Une ligne du livre ouvre le bulletin de son agent.
  void openPayslip(String staffMemberId) => emit(
    state.copyWith(
      payslipMemberId: () => staffMemberId,
      tab: PayrollTab.payslips,
    ),
  );

  void selectPayslip(String staffMemberId) =>
      emit(state.copyWith(payslipMemberId: () => staffMemberId));

  // ── Filtres ───────────────────────────────────────────────────────────

  void toggleContract(StaffContractKind? kind) => emit(
    state.copyWith(
      contractFilter: () => state.contractFilter == kind ? null : kind,
    ),
  );

  void setPayFilter(PayrollPayFilter filter) =>
      emit(state.copyWith(payFilter: filter));

  void setSearch(String text) {
    if (text != state.search) emit(state.copyWith(search: text));
  }

  void resetFilters() => emit(
    state.copyWith(
      contractFilter: () => null,
      payFilter: PayrollPayFilter.all,
      search: '',
    ),
  );

  void setAdvanceFilter(PayrollAdvanceFilter filter) =>
      emit(state.copyWith(advanceFilter: filter));

  // ── Gestes ────────────────────────────────────────────────────────────

  /// Annonce sans rien écrire.
  void announce(PayrollNotice notice) =>
      emit(state.copyWith(notice: notice.withSeq(++_seq)));

  /// Exécute un geste des [commands], relit la tablette et annonce l'issue.
  Future<void> perform(
    Future<PayrollNotice?> Function(PayrollCommands commands) gesture,
  ) async {
    final notice = await gesture(commands);
    if (isClosed) return;
    await refresh();
    if (isClosed || notice == null) return;
    emit(state.copyWith(notice: notice.withSeq(++_seq)));
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
