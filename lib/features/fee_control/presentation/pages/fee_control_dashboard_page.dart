import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_filters.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_ranking.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_summary_band.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/states/fee_control_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tableau de bord du Contrôle des frais : pour un frais, quelle part des
/// élèves est en ordre, et quels niveaux décrochent.
///
/// Même anatomie que l'écran nominatif (gate du contexte académique, réglages
/// puis résultats), mais il **pose la question** là où l'autre **donne les
/// noms**. Lecture 100 % locale, aucune écriture.
class FeeControlDashboardPage extends StatelessWidget {
  const FeeControlDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeeControlDashboardBloc>(
      create: (_) => getIt<FeeControlDashboardBloc>(),
      child: const _FeeControlDashboardView(),
    );
  }
}

class _FeeControlDashboardView extends StatefulWidget {
  const _FeeControlDashboardView();

  @override
  State<_FeeControlDashboardView> createState() =>
      _FeeControlDashboardViewState();
}

class _FeeControlDashboardViewState extends State<_FeeControlDashboardView> {
  /// Réglages du formulaire, tenus ici et non dans l'état du bloc : entre le
  /// choix et le résultat, `lastQuery` porte encore la lecture précédente, et un
  /// sélecteur qui s'y adosserait sauterait en arrière le temps du chargement.
  String? _feeCode;
  String? _cycleId;

  /// Vrai tant que l'écran n'a pas ouvert de lui-même sur le frais le plus
  /// porté. Un tableau de bord se lit ; le faire attendre un choix imposerait un
  /// clic chaque matin pour la même question.
  bool _awaitingAutoSelection = true;

  /// Année pour laquelle la liste des natures de frais a déjà été demandée.
  ///
  /// ⚠️ **Personne ne la demandait.** L'écran écoutait `feeCodes` sans que rien
  /// n'émette jamais l'événement qui les charge : le sélecteur restait vide et
  /// désactivé, l'auto-sélection n'avait aucune liste sur quoi s'ouvrir, et le
  /// tableau de bord n'affichait rien — sans la moindre erreur, sur un appareil
  /// dont le grand-livre était plein. La lecture s'amorce donc ici, le contexte
  /// académique connu, et **une seule fois par année** : le `build` est rejoué
  /// à chaque frappe de l'un des deux sélecteurs.
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
    final feeCode = _feeCode;
    if (feeCode == null) return;
    context.read<FeeControlDashboardBloc>().add(
      FeeControlDashboardRequested(
        academicYearId: academicYearId,
        feeCode: feeCode,
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
          if (academicYearState.status ==
                  AcademicYearContextLoadStatus.loading ||
              academicYearState.status ==
                  AcademicYearContextLoadStatus.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (academicYearState.status !=
              AcademicYearContextLoadStatus.success) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final academicYearId =
              academicYearState.context?.academicYear.id ?? '';
          final bundles =
              academicYearState.context?.schoolLevelGroups ?? const [];

          // Hors frame de build : émettre un événement pendant la construction
          // ferait rebâtir sous soi-même.
          if (_feeCodesRequestedFor != academicYearId) {
            _feeCodesRequestedFor = academicYearId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<FeeControlDashboardBloc>().add(
                FeeControlDashboardFeeCodesRequested(
                  academicYearId: academicYearId,
                ),
              );
            });
          }

          return _Body(
            academicYearId: academicYearId,
            labels: FeeControlDashboardLabels.from(bundles),
            cycles: FeeControlDashboardLabels.cycles(bundles),
            feeCode: _feeCode,
            cycleId: _cycleId,
            onFeeCodeChanged: (code) {
              if (code == null) return;
              setState(() => _feeCode = code);
              _load(academicYearId);
            },
            onCycleChanged: (value) {
              setState(
                () => _cycleId =
                    value == FeeControlDashboardFilters.allCyclesValue
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
              setState(() => _feeCode = codes.first);
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
  final String? feeCode;
  final String? cycleId;
  final ValueChanged<String?> onFeeCodeChanged;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<List<String>> onFeeCodesLoaded;

  const _Body({
    required this.academicYearId,
    required this.labels,
    required this.cycles,
    required this.feeCode,
    required this.cycleId,
    required this.onFeeCodeChanged,
    required this.onCycleChanged,
    required this.onFeeCodesLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<FeeControlDashboardBloc, FeeControlDashboardState>(
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
          // L'état d'erreur des natures affiche le type ET le message : les
          // omettre ici les figerait sur ceux de la première tentative.
          prev.errorType != curr.errorType ||
          prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        // La lecture des natures a échoué : le sélecteur n'offrirait rien, et
        // l'écran resterait aussi muet que s'il n'y avait rien à contrôler.
        // Deux causes très différentes derrière le même vide — on les sépare,
        // et on offre la reprise. L'échec est local : le wrapper ne proposera
        // jamais de « reconnexion ».
        if (state.feeCodesStatus == EnrollmentLoadStatus.failure) {
          return EnrollmentResultsErrorState(
            type: state.errorType ?? EnrollmentErrorType.unknown,
            message: state.errorMessage,
            onRetry: () => context.read<FeeControlDashboardBloc>().add(
              FeeControlDashboardFeeCodesRequested(
                academicYearId: academicYearId,
              ),
            ),
          );
        }

        // Aucune créance sur l'appareil : il n'y a rien à contrôler, et le
        // sélecteur n'offrirait rien. On le dit, plutôt que d'afficher deux
        // champs inertes.
        if (state.feeCodesStatus == EnrollmentLoadStatus.success &&
            state.feeCodes.isEmpty) {
          return FeeControlDashboardEmptyState(
            title: l10n.feeControlDashboardNoFeesTitle,
            description: l10n.feeControlDashboardNoFeesDescription,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeeControlDashboardFilters(
              feeCodes: state.feeCodes,
              selectedFeeCode: feeCode,
              cycles: cycles,
              selectedCycleId: cycleId,
              enabled: state.status != EnrollmentLoadStatus.loading,
              onFeeCodeChanged: onFeeCodeChanged,
              onCycleChanged: onCycleChanged,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            const FeeControlDashboardSummaryBand(),
            FeeControlDashboardRanking(
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
}
