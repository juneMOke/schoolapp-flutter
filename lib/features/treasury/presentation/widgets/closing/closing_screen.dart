import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_period_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_scope_tabs.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_view.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_status_banner.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/closing_report_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_panel.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/navigation/screen_back_scope.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_location.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de l'écran, câblés par la page ; `null` quand ils ne sont pas
/// offerts (droits).
class ClosingCallbacks {
  final void Function(CashDaySummary summary)? close;
  final void Function(CashDaySummary summary)? reopen;
  final Future<void> Function(CashMovement movement, bool alreadyCounted)?
  answer;
  final VoidCallback? configure;

  const ClosingCallbacks({
    this.close,
    this.reopen,
    this.answer,
    this.configure,
  });
}

/// Trésorerie ▸ Clôture de caisse, vue journalière (B1–B5).
class ClosingScreen extends StatefulWidget {
  final ClosingCallbacks callbacks;
  final bool online;

  const ClosingScreen({
    super.key,
    required this.callbacks,
    required this.online,
  });

  @override
  State<ClosingScreen> createState() => _ClosingScreenState();
}

class _ClosingScreenState extends State<ClosingScreen> {
  /// Journalier à l'ouverture ; le filtre n'est pas mémorisé d'une visite à
  /// l'autre (B1), mais l'adresse le garde (F5, lien).
  var _scope = ClosingScope.day;

  /// La semaine ou le mois affiché, pour les relire avec la journée.
  CashPeriodCubit? _period;

  /// Le premier jour de la semaine ou du mois affiché ; `null` pour la
  /// période en cours.
  DateTime? _periodFrom;

  /// La vue d'où l'on a ouvert la journée affichée : le retour Android y
  /// remonte au lieu de quitter l'écran.
  ClosingScope? _returnTo;

  ClosingCallbacks get callbacks => widget.callbacks;
  bool get online => widget.online;

  void _openDay(DateTime day) {
    setState(() {
      _returnTo = _scope == ClosingScope.day ? null : _scope;
      _scope = ClosingScope.day;
    });
    context.read<CashClosingCubit>().load(day);
  }

  /// F5 : la journée, et la semaine ou le mois s'ils sont affichés.
  Future<void> _refresh() async {
    final period = _scope == ClosingScope.day ? null : _period;
    await Future.wait([
      context.read<CashClosingCubit>().refresh(),
      if (period != null && !period.isClosed) period.load(),
    ]);
  }

  void _scopeChanged(ClosingScope scope) => setState(() {
    _scope = scope;
    _periodFrom = null;
    _returnTo = null;
  });

  /// Retour depuis une journée ouverte dans la semaine ou le mois : la même
  /// période revient (son début est gardé).
  void _backToPeriod() => setState(() {
    _scope = _returnTo ?? _scope;
    _returnTo = null;
  });

  /// L'adresse a changé (F5, Précédent, lien) : l'écran la suit.
  void _followLocation(Map<String, String?> values) {
    final scope = TreasuryLocation.scopeOf(values[TreasuryLocation.viewParam]);
    final cubit = context.read<CashClosingCubit>();
    if (scope == ClosingScope.day) {
      if (_scope != scope) setState(() => _scope = scope);
      final day = TreasuryLocation.dayOf(values[TreasuryLocation.dayParam]);
      if (day == null) {
        cubit.goToday();
      } else if (day != cubit.state.date) {
        cubit.load(day);
      }
      return;
    }
    final from = TreasuryLocation.dayOf(values[TreasuryLocation.periodParam]);
    if (scope != _scope) {
      setState(() {
        _scope = scope;
        _periodFrom = from;
      });
      return;
    }
    final period = _period;
    if (period != null && !period.isClosed) period.goTo(from);
  }

  Map<String, String?> _location(CashClosingState state) {
    final today = state.businessDate;
    final day = _scope == ClosingScope.day;
    return {
      TreasuryLocation.viewParam: TreasuryLocation.viewOf(_scope),
      TreasuryLocation.dayParam: day && today != null && state.date != today
          ? TreasuryLocation.write(state.date)
          : null,
      TreasuryLocation.periodParam: day
          ? null
          : TreasuryLocation.write(_periodFrom),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenBackScope(
      canPop: _returnTo == null || _scope != ClosingScope.day,
      onBack: _backToPeriod,
      child: TreasuryRefreshScope(
        onRefresh: _refresh,
        child: BlocBuilder<CashClosingCubit, CashClosingState>(
          buildWhen: (previous, current) =>
              previous.date != current.date ||
              previous.businessDate != current.businessDate,
          builder: (context, state) => LocationParamsSync(
            current: _location(state),
            onLocation: _followLocation,
            child: _build(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<CashClosingCubit, CashClosingState>(
      builder: (context, state) {
        final cubit = context.read<CashClosingCubit>();
        final businessDate = state.businessDate;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloPageHeader(
              titleStyle: TreasuryTitle.style(context),
              eyebrow: l10n.menuTreasury,
              title: l10n.treasuryClosingTitle,
              subtitle: l10n.treasuryClosingSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Semaine et mois ne s'offrent qu'une fois les caisses connues :
            // leurs bornes viennent du jour du serveur et de la première mise
            // en service.
            if (_scope != ClosingScope.day &&
                businessDate != null &&
                state.historyStart != null)
              BlocProvider(
                key: ValueKey(_scope),
                create: (_) => _period = CashPeriodCubit(
                  GetIt.instance<TreasuryDayRepository>(),
                  scope: _scope,
                  today: businessDate,
                  historyStart: state.historyStart!,
                  from: _periodFrom,
                )..load(),
                child: BlocListener<CashPeriodCubit, CashPeriodState>(
                  listenWhen: (previous, current) =>
                      previous.from != current.from,
                  listener: (context, period) => setState(
                    () =>
                        _periodFrom = context.read<CashPeriodCubit>().isCurrent
                        ? null
                        : period.from,
                  ),
                  child: PeriodView(
                    onOpenDay: _openDay,
                    today: businessDate,
                    filters: _tabs(),
                  ),
                ),
              )
            // La barre reste dès que le serveur a dit quel jour on est, même
            // si la journée affichée échoue : on peut toujours en sortir.
            else ...[
              if (businessDate != null) ...[
                DayNavBar(
                  date: state.date,
                  isToday: state.date == businessDate,
                  onPrevious: cubit.nextDay(-1) == null
                      ? null
                      : () => cubit.step(-1),
                  onNext: cubit.nextDay(1) == null ? null : () => cubit.step(1),
                  onToday: cubit.goToday,
                  filters: state.historyStart == null ? null : _tabs(),
                  onPickDate: state.historyStart == null
                      ? null
                      : () => _pickDate(context, state),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _body(context, state),
            ],
          ],
        );
      },
    );
  }

  Widget _tabs() => ClosingScopeTabs(scope: _scope, onChanged: _scopeChanged);

  /// Le sélecteur de date du Journalier : borné au début de l'historique et
  /// à aujourd'hui, dimanches exclus (R4).
  Future<void> _pickDate(BuildContext context, CashClosingState state) async {
    final today = state.businessDate;
    final first = state.historyStart;
    if (today == null || first == null) return;
    final cubit = context.read<CashClosingCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: first,
      lastDate: today,
      selectableDayPredicate: (day) => day.weekday != DateTime.sunday,
    );
    if (picked == null || !context.mounted) return;
    await cubit.load(picked);
  }

  Widget _body(BuildContext context, CashClosingState state) {
    final l10n = AppLocalizations.of(context)!;
    final day = state.day;
    final configure = callbacks.configure;
    return switch (state.status) {
      CashClosingStatus.loading => EteeloListSkeleton(
        rowCount: 2,
        pillCount: 2,
        showAvatar: false,
        semanticsLabel: l10n.treasuryDayLoading,
      ),
      CashClosingStatus.failure => TreasuryResultsErrorState(
        failure: state.failure ?? const ServerFailure(),
        onRetry: context.read<CashClosingCubit>().load,
      ),
      _ when day == null || day.registers.isEmpty => EteeloEmptyResult(
        label: l10n.treasuryEmptyTitle,
        description: l10n.treasuryEmptyClosing,
        medallionIcon: Icons.payments_outlined,
        fullWidthCard: true,
        primaryAction: configure == null
            ? null
            : EteeloButton.primary(
                label: l10n.treasuryConfigureRegisters,
                icon: Icons.settings_outlined,
                onPressed: configure,
                fullWidth: false,
              ),
      ),
      _ => _day(context, state, day),
    };
  }

  Widget _day(BuildContext context, CashClosingState state, TreasuryDay day) {
    final blocks = {
      for (final summary in day.registers)
        summary.register.id: CashClosingRules.blockOf(
          isToday: day.isToday,
          sunday: state.sunday,
          closed: summary.isClosed,
          canClose: callbacks.close != null,
          online: online,
          pendingSyncCount: state.pendingSync[summary.register.currency] ?? 0,
          pendingAfterClosureCount: summary.pendingAfterClosureCount,
        ),
    };
    final close = callbacks.close;
    final next = day.registers
        .where((s) => blocks[s.register.id] == null)
        .firstOrNull;
    // Une ligne arrivée après une clôture se règle sur sa propre journée,
    // même passée : le serveur compte toutes celles qui attendent jusqu'à
    // aujourd'hui, et refuserait la clôture du jour tant qu'il en reste une.
    final answer = online ? callbacks.answer : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DayStatusBanner(
          day: day,
          nextRegisterName: next?.register.name,
          onCloseNext: next == null || close == null ? null : () => close(next),
        ),
        const SizedBox(height: AppSpacing.lg),
        EteeloGridView(
          itemCount: day.registers.length,
          padding: EdgeInsets.zero,
          minItemWidth: AppDimensions.treasuryDayCardMinWidth,
          spacing: AppSpacing.lg,
          itemBuilder: (context, index) {
            final summary = day.registers[index];
            final reopen = callbacks.reopen;
            return DayCard(
              key: ValueKey('${summary.register.id}-${day.date}'),
              summary: summary,
              date: day.date,
              isToday: day.isToday,
              block: blocks[summary.register.id],
              pendingSyncCount:
                  state.pendingSync[summary.register.currency] ?? 0,
              onClose: close == null ? null : () => close(summary),
              onReopen:
                  reopen != null && online && day.isToday && summary.isClosed
                  ? () => reopen(summary)
                  : null,
              onAnswer: answer,
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ClosingReportBar(
          label: AppLocalizations.of(context)!.treasuryReportOneDaily,
          title: capitalizeFirst(
            AppLocalizations.of(context)!.treasuryDayLong(day.date),
          ),
          reportId: CashReportIds.daily(day.date),
          remainingRegisters: day.registers.length - day.closedCount,
          pastNotClosed: !day.isToday && day.closedCount < day.registers.length,
        ),
      ],
    );
  }
}
