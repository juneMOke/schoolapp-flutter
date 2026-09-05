import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_header.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_window_tabs.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_success_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_headcount_banner.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Inscriptions › Tableau de bord — **une fenêtre de temps sur un fait unique**.
///
/// L'écran répond à trois questions dans cet ordre : **combien** d'élèves,
/// **qui** ils sont, **où** ils vont. Il est en lecture seule : aucune mutation
/// ne part d'ici, seulement des sorties et des renvois.
///
/// ## Ce que la machine à états décide
///
/// Les quatre états ne sont pas des nuances d'affichage, ils décident quels
/// blocs **existent** :
///
///  - **loading** — la silhouette de la page, jamais un rond qui tourne ;
///  - **ready** — la grille complète ;
///  - **empty** — l'en-tête reste, le contenu cède la place à une issue ;
///  - **error** — l'erreur **remplace tout le contenu sous l'en-tête**.
///
/// Ce dernier point est une règle, pas une préférence : « sans données,
/// l'effectif affiché serait un mensonge ». Elle est tenue **à la source** — le
/// bloc vide `stats` en même temps qu'il émet l'échec — plutôt que par des
/// conditions recopiées dans chaque bloc, qu'un widget distrait finirait par
/// oublier.
///
/// ## Pas de snackbar sur un échec de chargement
///
/// L'erreur s'affiche **en place**. La version précédente doublait la vue
/// d'erreur d'un `SnackBar` : deux signalements pour un seul incident, dont un
/// qui s'efface tout seul et recouvre le bouton de reprise.
class EnrollmentStatsDashboardPage extends StatefulWidget {
  const EnrollmentStatsDashboardPage({super.key});

  @override
  State<EnrollmentStatsDashboardPage> createState() =>
      _EnrollmentStatsDashboardPageState();
}

class _EnrollmentStatsDashboardPageState
    extends State<EnrollmentStatsDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<EnrollmentStatsBloc>().add(const EnrollmentStatsRequested());
  }

  void _retry() => context.read<EnrollmentStatsBloc>().add(
    const EnrollmentStatsRefreshRequested(),
  );

  void _seeWholeYear() => context.read<EnrollmentStatsBloc>().add(
    const EnrollmentStatsRequested(window: EnrollmentStatsWindow.year()),
  );

  void _openPreRegistrations() {
    final l10n = AppLocalizations.of(context)!;
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: MenuConstants.inscriptionsMenuId,
        subMenuId: MenuConstants.preInscriptionsId,
        title: l10n.subMenuPreRegistrations,
      ),
    );
  }

  void _openFirstRegistration() {
    final l10n = AppLocalizations.of(context)!;
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: MenuConstants.inscriptionsMenuId,
        subMenuId: MenuConstants.premiereInscriptionId,
        title: l10n.subMenuFirstRegistration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: BlocBuilder<EnrollmentStatsBloc, EnrollmentStatsState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.stats != curr.stats ||
            prev.failure != curr.failure ||
            prev.window != curr.window,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // L'en-tête survit aux quatre états : c'est le seul repère qui ne
              // dépende d'aucune donnée.
              EnrollmentDashboardHeader(
                schoolYear: state.stats?.context.schoolYear,
                generatedAt: state.stats?.context.generatedAt,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Le bandeau d'effectif ne paraît qu'aux deux états qui portent
              // des chiffres, prêt ET vide — à l'état vide il reste avec son
              // zéro, qui est le repère de lecture de l'écran.
              //
              // Pas pendant le chargement : un effectif est une donnée qu'on
              // n'a pas encore. Pas en erreur non plus, où l'afficher depuis
              // une lecture précédente serait un mensonge — le bloc a d'ailleurs
              // vidé `stats`, il ne reste rien à afficher.
              //
              // ⚠️ Conséquence assumée : au changement de fenêtre, le bandeau
              // disparaît puis revient avec la MÊME valeur, puisque l'effectif
              // ne dépend pas de la fenêtre. C'est la règle de la spec ; si le
              // clignotement gêne à l'usage, c'est cette condition-ci qu'il
              // faudra assouplir, pas le calcul.
              if (state.stats != null &&
                  (state.status == EnrollmentStatsStatus.success ||
                      state.status == EnrollmentStatsStatus.empty)) ...[
                EnrollmentHeadcountBanner(
                  headcount: state.stats!.headcount,
                  schoolYear: state.stats!.context.schoolYear,
                ),
              ],
              // Le sélecteur de fenêtre disparaît en erreur : sans données il
              // n'y a pas de fenêtre à choisir, et l'offrir inviterait à
              // relancer en boucle une lecture qui n'a pas échoué pour ça.
              if (state.status != EnrollmentStatsStatus.error) ...[
                const EnrollmentDashboardWindowTabs(),
                const SizedBox(height: AppDimensions.spacingL),
              ],
              AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<EnrollmentStatsStatus>(state.status),
                  child: _buildBody(context, state),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXL),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, EnrollmentStatsState state) {
    final l10n = AppLocalizations.of(context)!;

    return switch (state.status) {
      EnrollmentStatsStatus.initial => const SizedBox.shrink(),
      EnrollmentStatsStatus.loading => const EnrollmentDashboardSkeleton(
        kpiCount: 4,
      ),
      EnrollmentStatsStatus.success => EnrollmentDashboardSuccessView(
        stats: state.stats!,
        windowLabel: _windowLabel(l10n, state.window.kind),
        isSingleDay: state.window.isSingleDay,
        // Une ligne de niveau renvoie vers Première inscription — c'est la
        // sortie « où en ajouter » de la spec.
        //
        // ⚠️ Le niveau cliqué N'EST PAS transmis : l'écran d'arrivée ne sait
        // pas encore recevoir de cadrage. `LevelStat.id` est déjà au contrat
        // et arrive jusqu'ici, il ne manque que le destinataire. Renvoyer sans
        // le niveau est ce que la spec demande ; le jour où l'écran d'arrivée
        // acceptera une intention, c'est ici que ça se branche.
        onLevelTap: (_) => _openFirstRegistration(),
        onOpenPreRegistrations: _openPreRegistrations,
      ),
      EnrollmentStatsStatus.empty => EnrollmentDashboardEmptyState(
        windowLabel: _windowLabel(l10n, state.window.kind),
        // « La plus large » est une propriété de la fenêtre, pas une règle de
        // l'écran : c'est l'entité qui répond.
        isWidestWindow: state.window.isWidest,
        onSeeWholeYear: state.window.isWidest ? null : _seeWholeYear,
        onOpenFirstRegistration: _openFirstRegistration,
      ),
      EnrollmentStatsStatus.error => EnrollmentDashboardErrorState(
        failure: state.failure ?? const ServerFailure('unknown failure'),
        onRetry: _retry,
      ),
    };
  }

  /// Le libellé de la fenêtre, tel qu'il est écrit sur son onglet.
  ///
  /// Le vide nomme ce qui a été cherché : « Aucune inscription · Cette
  /// semaine » se comprend, « Aucune inscription » tout court laisse croire que
  /// l'école est vide.
  String _windowLabel(AppLocalizations l10n, EnrollmentStatsWindowKind kind) =>
      switch (kind) {
        EnrollmentStatsWindowKind.day => l10n.enrollmentDashboardWindowDay,
        EnrollmentStatsWindowKind.week => l10n.enrollmentDashboardWindowWeek,
        EnrollmentStatsWindowKind.month => l10n.enrollmentDashboardWindowMonth,
        EnrollmentStatsWindowKind.year => l10n.enrollmentDashboardWindowYear,
        EnrollmentStatsWindowKind.custom =>
          l10n.enrollmentDashboardWindowCustom,
      };
}
