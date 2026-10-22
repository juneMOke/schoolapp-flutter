import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_sale_detail_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_academic_year_gate.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_body.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_header.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_provisional_notice.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Le tableau de bord de la boutique : « combien a-t-elle vendu, quoi, et à
/// quels élèves ? » — un flux, jamais un stock ni une dette.
class BoutiqueDashboardPage extends StatelessWidget {
  const BoutiqueDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<BoutiqueDashboardBloc>()),
      BlocProvider(create: (_) => getIt<BoutiqueBeneficiariesCubit>()),
    ],
    child: BoutiqueAcademicYearGate(
      builder: (context, year) => _DashboardView(year: year),
    ),
  );
}

class _DashboardView extends StatefulWidget {
  final AcademicYearContext? year;

  const _DashboardView({required this.year});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final GlobalKey _beneficiariesKey = GlobalKey();
  bool _beneficiariesStarted = false;

  String get _academicYearId => widget.year?.academicYear.id ?? '';

  /// Les libellés de niveaux servent au TICKET d'une vente walk-in, rouvert
  /// depuis « Dernières ventes ».
  Map<String, String> get _levelLabels => {
    for (final bundle
        in widget.year?.schoolLevelGroups ?? const <SchoolLevelGroupBundle>[])
      for (final level in bundle.levels) level.id: level.name,
  };

  @override
  void initState() {
    super.initState();
    context.read<BoutiqueDashboardBloc>().add(
      BoutiqueDashboardStarted(
        academicYearId: _academicYearId,
        yearStart: widget.year?.academicYear.startDate,
      ),
    );
  }

  /// La liste des élèves suit la fenêtre du tableau de bord ; ses filtres, eux,
  /// restent.
  void _onWindowChanged(BuildContext context, BoutiqueDashboardState state) {
    final window = state.window;
    if (window == null) return;
    final cubit = context.read<BoutiqueBeneficiariesCubit>();
    if (_beneficiariesStarted) {
      cubit.windowChanged(window);
    } else {
      _beneficiariesStarted = true;
      cubit.start(academicYearId: _academicYearId, window: window);
    }
  }

  void _openTill() => context.go(AppRoutesNames.boutiqueAchats);

  /// Un article du palmarès devient le filtre de la liste, et l'écran y
  /// descend : trois gestes, aucune saisie, pour « qui a déjà son polo ? ».
  Future<void> _onArticleTap(BoutiqueTopArticle article) async {
    await context.read<BoutiqueBeneficiariesCubit>().articleSelected(
      article.articleId,
      label: article.label,
    );
    if (!mounted) return;
    final target = _beneficiariesKey.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(target, duration: AppMotion.layout);
  }

  /// Rouvre la fiche, puis relit : elle a pu noter une impression ou réclamer
  /// le reçu scellé.
  Future<void> _openSale(SaleHistoryEntry sale) async {
    final bloc = context.read<BoutiqueDashboardBloc>();
    await BoutiqueSaleDetailPage.push(
      context,
      saleId: sale.id,
      levelLabels: _levelLabels,
    );
    if (!mounted) return;
    bloc.add(const BoutiqueDashboardRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<BoutiqueDashboardBloc, BoutiqueDashboardState>(
      listenWhen: (prev, curr) => prev.window != curr.window,
      listener: _onWindowChanged,
      child: AppPageBackground(
        width: PageContentWidth.wide,
        // Dans la coquille, sa barre d'en-tête nomme déjà l'écran.
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.boutiqueDashboardEyebrow,
                title: l10n.boutiqueDashboardTitle,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<BoutiqueDashboardBloc, BoutiqueDashboardState>(
              buildWhen: (prev, curr) =>
                  prev.period != curr.period ||
                  prev.window != curr.window ||
                  prev.cachedAt != curr.cachedAt,
              builder: (context, state) => BoutiqueDashboardHeader(
                period: state.period,
                window: state.window,
                cachedAt: state.cachedAt,
                onPeriodChanged: (period) => context
                    .read<BoutiqueDashboardBloc>()
                    .add(BoutiqueDashboardPeriodChanged(period)),
                onRefresh: () => context.read<BoutiqueDashboardBloc>().add(
                  const BoutiqueDashboardRefreshRequested(),
                ),
                onOpenTill: _openTill,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            // Visible même sous une erreur réseau : ces ventes-là, le poste
            // les connaît sans le serveur.
            BlocBuilder<BoutiqueDashboardBloc, BoutiqueDashboardState>(
              buildWhen: (prev, curr) => prev.provisional != curr.provisional,
              builder: (context, state) => state.provisional.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingM,
                      ),
                      child: BoutiqueProvisionalNotice(
                        provisional: state.provisional,
                      ),
                    ),
            ),
            BlocBuilder<BoutiqueDashboardBloc, BoutiqueDashboardState>(
              buildWhen: (prev, curr) =>
                  prev.status != curr.status ||
                  prev.stats != curr.stats ||
                  prev.failure != curr.failure ||
                  prev.refreshing != curr.refreshing ||
                  prev.latestSales != curr.latestSales ||
                  prev.selectedCurrency != curr.selectedCurrency ||
                  prev.window != curr.window,
              builder: (context, state) => BoutiqueDashboardBody(
                state: state,
                now: DateTime.now(),
                beneficiariesKey: _beneficiariesKey,
                onArticleTap: _onArticleTap,
                onOpenSale: _openSale,
                onOpenTill: _openTill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
