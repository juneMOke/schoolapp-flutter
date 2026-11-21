import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_period_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_scope_tabs.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_view.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_day_pane.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_period_split.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_day_view.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_panel.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_location_sync.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/navigation/screen_back_scope.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_location.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_button.dart';

export 'closing_day_view.dart' show ClosingCallbacks;

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
  State<ClosingScreen> createState() => ClosingScreenState();
}

class ClosingScreenState extends State<ClosingScreen> {
  /// Journalier à l'ouverture ; le filtre n'est pas mémorisé d'une visite à
  /// l'autre (B1), mais l'adresse le garde (F5, lien).
  var _scope = ClosingScope.day;

  /// La semaine ou le mois affiché, pour les relire avec la journée.
  CashPeriodCubit? _period;

  /// Le premier jour de la semaine ou du mois affiché ; `null` pour la
  /// période en cours.
  DateTime? _periodFrom;

  /// La semaine ou le mois, d'une forme d'écran à l'autre.
  final _periodKey = GlobalKey(debugLabel: 'closing-period');

  /// La vue d'où l'on a ouvert la journée affichée : le retour Android y
  /// remonte au lieu de quitter l'écran.
  ClosingScope? _returnTo;

  var _started = false;

  /// La première lecture part sur la journée de l'adresse (F5, lien) : une
  /// seule requête au montage, pas aujourd'hui puis la journée demandée.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    context.read<CashClosingCubit>().load(closingDayOf(context));
  }

  ClosingCallbacks get callbacks => widget.callbacks;
  bool get online => widget.online;

  void _openDay(DateTime day) {
    setState(() {
      _returnTo = _scope == ClosingScope.day ? null : _scope;
      _scope = ClosingScope.day;
    });
    context.read<CashClosingCubit>().load(day);
  }

  /// F5 ou la page tirée : la journée, et la semaine ou le mois s'ils sont
  /// affichés.
  Future<void> refresh() async {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenBackScope(
      canPop: _returnTo == null || _scope != ClosingScope.day,
      onBack: _backToPeriod,
      // La page tirée se pose au-dessus du défilement, dans la page.
      child: TreasuryRefreshScope(
        onRefresh: refresh,
        pull: false,
        child: BlocBuilder<CashClosingCubit, CashClosingState>(
          buildWhen: (previous, current) =>
              previous.date != current.date ||
              previous.businessDate != current.businessDate,
          builder: (context, state) => LocationParamsSync(
            current: TreasuryLocation.closing(
              scope: _scope,
              date: state.date,
              today: state.businessDate,
              periodFrom: _periodFrom,
            ),
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
        final businessDate = state.businessDate;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloPageHeader(
              actions: TreasuryRefreshButton.headerActions(context),
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
              _periodArea(context, state, businessDate)
            else
              ClosingDayPane(
                state: state,
                callbacks: callbacks,
                online: online,
                filters: _tabs(),
              ),
          ],
        );
      },
    );
  }

  /// La semaine ou le mois. Sur un écran large (10″ paysage, poste), la
  /// journée touchée s'ouvre à côté : on contrôle les six jours sans perdre
  /// la période. Plus étroit, elle remplace la période (retour : la période).
  Widget _periodArea(
    BuildContext context,
    CashClosingState state,
    DateTime businessDate,
  ) {
    final cubit = context.read<CashClosingCubit>();
    return ClosingPeriodSplit(
      // La période garde son état quand l'écran change de forme.
      period: (sideBySide, reveal) => KeyedSubtree(
        key: _periodKey,
        child: _periodProvider(
          businessDate,
          state,
          onOpenDay: sideBySide
              ? (day) {
                  cubit.load(day);
                  reveal();
                }
              : _openDay,
          selectedDay: sideBySide ? state.date : null,
        ),
      ),
      pane: ClosingDayPane(
        state: state,
        callbacks: callbacks,
        online: online,
        standalone: false,
      ),
    );
  }

  Widget _periodProvider(
    DateTime businessDate,
    CashClosingState state, {
    required ValueChanged<DateTime> onOpenDay,
    DateTime? selectedDay,
  }) => BlocProvider(
    key: ValueKey(_scope),
    create: (_) => _period = CashPeriodCubit(
      GetIt.instance<TreasuryDayRepository>(),
      scope: _scope,
      today: businessDate,
      historyStart: state.historyStart!,
      from: _periodFrom,
    )..load(),
    child: BlocListener<CashPeriodCubit, CashPeriodState>(
      listenWhen: (previous, current) => previous.from != current.from,
      listener: (context, period) => setState(
        () => _periodFrom = context.read<CashPeriodCubit>().isCurrent
            ? null
            : period.from,
      ),
      child: PeriodView(
        onOpenDay: onOpenDay,
        selectedDay: selectedDay,
        today: businessDate,
        filters: _tabs(),
      ),
    ),
  );

  Widget _tabs() => ClosingScopeTabs(scope: _scope, onChanged: _scopeChanged);
}
