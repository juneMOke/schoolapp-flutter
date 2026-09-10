import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_fee_rates_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_key_figures_band.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_perimeter_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_ranking_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/states/recouvrement_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tableau de bord du **Recouvrement** : où en est la dette sur une sélection de
/// frais, quels niveaux décrochent, et ce que coûterait un renvoi.
///
/// Même anatomie que l'écran nominatif (gate du contexte académique, réglages
/// puis résultats), mais il **pose la question** là où l'autre **donne les
/// noms**. Lecture 100 % locale ; le seul appel réseau de l'écran est l'émission
/// de la liste de relance.
class RecouvrementDashboardPage extends StatelessWidget {
  const RecouvrementDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RecouvrementDashboardBloc>(
          create: (_) => getIt<RecouvrementDashboardBloc>(),
        ),
        // Le taux du jour n'entre dans aucun total : il ne sert qu'à dire, sous
        // le périmètre, à quel cours s'arbitre une comparaison.
        BlocProvider<ExchangeRatesCubit>(
          create: (_) => getIt<ExchangeRatesCubit>()..load(),
        ),
      ],
      child: const _RecouvrementDashboardView(),
    );
  }
}

class _RecouvrementDashboardView extends StatefulWidget {
  const _RecouvrementDashboardView();

  @override
  State<_RecouvrementDashboardView> createState() =>
      _RecouvrementDashboardViewState();
}

class _RecouvrementDashboardViewState
    extends State<_RecouvrementDashboardView> {
  /// Réglages du formulaire, tenus ici et non dans l'état du bloc : entre le
  /// choix et le résultat, `lastQuery` porte encore la lecture précédente, et un
  /// sélecteur qui s'y adosserait sauterait en arrière le temps du chargement.
  Set<String> _feeCodes = <String>{};
  String? _cycleId;

  /// Vrai tant que l'écran n'a pas ouvert de lui-même sur le frais le plus
  /// porté. Un tableau de bord se lit ; le faire attendre un choix imposerait un
  /// clic chaque matin pour la même question.
  bool _awaitingAutoSelection = true;

  /// Année pour laquelle la liste des natures a déjà été demandée. Le `build`
  /// est rejoué à chaque frappe : sans elle, la lecture repartirait à chaque
  /// fois.
  String? _feeCodesRequestedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  void _load(String academicYearId) {
    if (_feeCodes.isEmpty) return;
    context.read<RecouvrementDashboardBloc>().add(
      RecouvrementRequested(
        academicYearId: academicYearId,
        feeCodes: _feeCodes.toList(),
        schoolLevelGroupId: _cycleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, academicYearState) {
          final status = academicYearState.status;
          if (status == AcademicYearContextLoadStatus.loading ||
              status == AcademicYearContextLoadStatus.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (status != AcademicYearContextLoadStatus.success) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final academicYearId =
              academicYearState.context?.academicYear.id ?? '';
          final bundles =
              academicYearState.context?.schoolLevelGroups ?? const [];

          // Hors frame de build : émettre pendant la construction ferait
          // rebâtir sous soi-même.
          if (_feeCodesRequestedFor != academicYearId) {
            _feeCodesRequestedFor = academicYearId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<RecouvrementDashboardBloc>().add(
                RecouvrementFeeCodesRequested(academicYearId: academicYearId),
              );
            });
          }

          return _Body(
            academicYearId: academicYearId,
            labels: FeeControlDashboardLabels.from(bundles),
            cycles: FeeControlDashboardLabels.cycles(bundles),
            feeCodes: _feeCodes,
            cycleId: _cycleId,
            onFeeCodesChanged: (codes) {
              if (codes.isEmpty) return;
              setState(() => _feeCodes = codes);
              _load(academicYearId);
            },
            onCycleChanged: (value) {
              setState(
                () =>
                    _cycleId = value == RecouvrementPerimeterCard.allCyclesValue
                    ? null
                    : value,
              );
              _load(academicYearId);
            },
            onFeeCodesLoaded: (codes) {
              if (!_awaitingAutoSelection || codes.isEmpty) return;
              // La première nature est **la plus portée** (le DAO les trie par
              // effectif) : ouvrir dessus, c'est ouvrir sur la question du
              // matin plutôt que sur un frais marginal.
              _awaitingAutoSelection = false;
              setState(() => _feeCodes = {codes.first});
              _load(academicYearId);
            },
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String academicYearId;
  final FeeControlDashboardLabels labels;
  final List<FeeControlCycleOption> cycles;
  final Set<String> feeCodes;
  final String? cycleId;
  final ValueChanged<Set<String>> onFeeCodesChanged;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<List<String>> onFeeCodesLoaded;

  const _Body({
    required this.academicYearId,
    required this.labels,
    required this.cycles,
    required this.feeCodes,
    required this.cycleId,
    required this.onFeeCodesChanged,
    required this.onCycleChanged,
    required this.onFeeCodesLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      listenWhen: (prev, curr) =>
          prev.feeCodesStatus != curr.feeCodesStatus ||
          prev.feeCodes != curr.feeCodes,
      listener: (context, state) {
        if (state.feeCodesStatus != EnrollmentLoadStatus.success) return;
        onFeeCodesLoaded(state.feeCodes);
      },
      buildWhen: (prev, curr) =>
          prev.feeCodesStatus != curr.feeCodesStatus ||
          prev.feeCodes != curr.feeCodes ||
          prev.status != curr.status ||
          prev.figures != curr.figures ||
          prev.rates != curr.rates ||
          prev.unbilled != curr.unbilled ||
          // L'état d'erreur des natures affiche le type ET le message : les
          // omettre ici les figerait sur ceux de la première tentative.
          prev.errorType != curr.errorType ||
          prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        // La lecture des natures a échoué : le sélecteur n'offrirait rien, et
        // l'écran resterait aussi muet que s'il n'y avait rien à recouvrer.
        // L'échec est local : le wrapper ne proposera jamais de reconnexion.
        if (state.feeCodesStatus == EnrollmentLoadStatus.failure) {
          return EnrollmentResultsErrorState(
            type: state.errorType ?? EnrollmentErrorType.unknown,
            message: state.errorMessage,
            onRetry: () => context.read<RecouvrementDashboardBloc>().add(
              RecouvrementFeeCodesRequested(academicYearId: academicYearId),
            ),
          );
        }

        // Aucune créance sur l'appareil : il n'y a rien à recouvrer, et le
        // sélecteur n'offrirait rien. On le dit, plutôt que d'afficher des
        // champs inertes. C'est le vide STRUCTUREL de la spec §12 — il remplace
        // tout le contenu, périmètre compris : choisir des frais qui n'existent
        // pas serait absurde.
        if (state.feeCodesStatus == EnrollmentLoadStatus.success &&
            state.feeCodes.isEmpty) {
          return RecouvrementDashboardEmptyState(
            title: l10n.feeControlDashboardNoFeesTitle,
            description: l10n.feeControlDashboardNoFeesDescription,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<ExchangeRatesCubit, ExchangeRatesState>(
              buildWhen: (prev, curr) => prev.rates != curr.rates,
              builder: (context, ratesState) => RecouvrementPerimeterCard(
                feeCodes: state.feeCodes,
                selectedFeeCodes: feeCodes,
                cycles: cycles,
                selectedCycleId: cycleId,
                enabled: state.status != EnrollmentLoadStatus.loading,
                onFeeCodesChanged: onFeeCodesChanged,
                onCycleChanged: onCycleChanged,
                concernedCount: state.status == EnrollmentLoadStatus.success
                    ? state.figures.total
                    : null,
                unbilled: state.unbilled,
                exchangeRate: _dollarInFrancs(ratesState.rates),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            const RecouvrementKeyFiguresBand(),
            RecouvrementFeeRatesSection(groups: state.rates),
            RecouvrementRankingSection(
              labels: labels,
              academicYearId: academicYearId,
              // Sans filtre de cycle, deux « 1ère année » de cycles différents
              // deviendraient indiscernables dans le classement.
              showCycleInLabels: cycleId == null,
            ),
          ],
        );
      },
    );
  }

  /// Le taux dollar → franc en vigueur, ou `null` si l'école n'en a posé aucun.
  ///
  /// Le sens contraire rend `null` plutôt qu'un taux retourné : l'inverse d'un
  /// taux arrondi n'est pas le taux inverse.
  static ExchangeRate? _dollarInFrancs(List<ExchangeRate> rates) =>
      ExchangeRates.at(
        rates,
        base: CurrencyCode.usd,
        quote: CurrencyCode.cdf,
        moment: DateTime.now(),
      );
}
