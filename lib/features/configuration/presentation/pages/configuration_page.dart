import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/activation_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_app_bar.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_step_content.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_step_footer.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Coquille de l'assistant de mise en service de l'école.
///
/// Route de premier niveau (`/configuration`), volontairement hors de la
/// coquille de l'application : elle doit s'ouvrir alors que l'école n'a pas
/// encore d'année académique, donc au moment précis où le menu et le tableau de
/// bord n'ont rien à afficher. La garde de route confronte
/// `school.provisioning.write` (cf. `kStandaloneRouteAccess`).
class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `registerFactory` côté DI et création ici : le bloc porte le brouillon en
    // cours, et le partager entre deux ouvertures ferait reprendre l'assistant
    // sur un état qu'on croyait quitté.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConfigurationBloc>(
          create: (_) =>
              getIt<ConfigurationBloc>()..add(const ConfigurationStarted()),
        ),
        // L'étape 1 a son propre cycle de vie : elle lit et écrit sur
        // `/schools/{id}`, n'entre jamais dans le brouillon, et n'a rien à
        // simuler. Deux régimes de persistance, deux porteurs d'état.
        BlocProvider<SchoolIdentityFormCubit>(
          create: (_) => getIt<SchoolIdentityFormCubit>()..load(),
        ),
      ],
      child: const _ConfigurationView(),
    );
  }
}

class _ConfigurationView extends StatelessWidget {
  const _ConfigurationView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < AppBreakpoints.configurationCompactMax;

    final titles = <String>[
      l10n.configurationStepSchool,
      l10n.configurationStepAcademicYear,
      l10n.configurationStepStructure,
      l10n.configurationStepFees,
      l10n.configurationStepActivation,
    ];

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      // Le rail ne se reconstruit que sur ce dont il dépend : l'étape, le rang
      // atteint et les étapes validées. Sans ce filtre, chaque frappe dans un
      // champ redessinerait les cinq pastilles et leurs animations.
      buildWhen: (previous, current) =>
          previous.step != current.step ||
          previous.maxStep != current.maxStep ||
          previous.doneSteps != current.doneSteps ||
          previous.isActivated != current.isActivated,
      builder: (context, state) {
        // L'école est en service : l'assistant s'efface. Y laisser le stepper
        // inviterait à revenir sur des étapes que le serveur refuserait de
        // rejouer.
        if (state.activatedPlan case final plan?) {
          return AppPageBackground(
            scrollable: false,
            child: ActivationSuccessView(
              schoolName:
                  context
                      .watch<SchoolIdentityFormCubit>()
                      .state
                      .identity
                      ?.name ??
                  '',
              plan: plan,
              onGoHome: () => context.goNamed(AppRoutesNames.home),
              onReview: () => context.read<ConfigurationBloc>().add(
                const ConfigurationStepSelected(ConfigurationStep.school),
              ),
            ),
          );
        }

        return AppPageBackground(
          scrollable: false,
          appBar: ConfigurationAppBar(
            stepNumber: state.step.rank + 1,
            stepCount: ConfigurationStep.count,
            onExit: () => _exit(context),
          ),
          child: Column(
            children: [
              ConfigurationStepper(
                progression: state.progression,
                titles: titles,
                compact: compact,
                onStepTap: (index) => context.read<ConfigurationBloc>().add(
                  ConfigurationStepSelected(ConfigurationStep.values[index]),
                ),
              ),
              const Expanded(child: _StepBody()),
              const ConfigurationStepFooter(),
            ],
          ),
        );
      },
    );
  }

  /// Sortie de l'assistant, sans confirmation : tout est enregistré.
  ///
  /// `pop()` quand la pile le permet — l'assistant a pu être ouvert depuis les
  /// réglages, et y revenir est le geste attendu. Sinon l'accueil : un
  /// `goNamed` inconditionnel écraserait une pile où l'écran d'origine vit
  /// encore, ce qui a déjà coûté un sous-arbre jamais remonté ailleurs dans
  /// cette application.
  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(AppRoutesNames.home);
  }
}

/// Corps de l'étape courante.
///
/// Les cinq étapes arrivent avec les lots suivants ; cette enveloppe porte
/// l'animation d'entrée et le rembourrage, qui leur sont communs.
class _StepBody extends StatelessWidget {
  const _StepBody();

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) => previous.step != current.step,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : AppMotion.stepIn,
          child: SingleChildScrollView(
            // La clé est l'étape, et pas l'index d'un widget : sans elle,
            // l'AnimatedSwitcher réutiliserait le même élément d'une étape à
            // l'autre et n'animerait rien.
            key: ValueKey<ConfigurationStep>(state.step),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const ConfigurationStepContent(),
          ),
        );
      },
    );
  }
}
