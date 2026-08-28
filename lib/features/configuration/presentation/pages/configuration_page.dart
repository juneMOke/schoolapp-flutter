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
import 'package:school_app_flutter/features/configuration/presentation/steps/academic_year_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/school_identity_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_app_bar.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_save_bar.dart';
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
          previous.doneSteps != current.doneSteps,
      builder: (context, state) {
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
              const _StepFooter(),
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
            child: switch (state.step) {
              ConfigurationStep.school => const SchoolIdentityStep(),
              ConfigurationStep.academicYear => const AcademicYearStep(),
              // Les trois autres étapes arrivent avec les lots suivants.
              _ => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}

/// Barre de pied de l'étape courante.
///
/// L'étape 1 y parle un autre langage que les suivantes : elle écrit vraiment,
/// donc elle dit « Enregistré » là où les autres diront « Brouillon
/// enregistré ». C'est la seule trace visible d'une distinction qui décide de
/// ce qui survit à la fermeture de l'application.
class _StepFooter extends StatelessWidget {
  const _StepFooter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) => previous.step != current.step,
      builder: (context, state) => switch (state.step) {
        ConfigurationStep.school => const _SchoolStepFooter(),
        ConfigurationStep.academicYear => const _DraftStepFooter(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _SchoolStepFooter extends StatelessWidget {
  const _SchoolStepFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      builder: (context, state) {
        final cubit = context.read<SchoolIdentityFormCubit>();
        final blocked =
            state.status == SchoolIdentityFormStatus.saving ||
            state.status == SchoolIdentityFormStatus.loading ||
            state.status == SchoolIdentityFormStatus.failure;

        return ConfigurationSaveBar(
          mode: switch (state.status) {
            SchoolIdentityFormStatus.saving => ConfigurationSaveBarMode.saving,
            _ when state.justSaved => ConfigurationSaveBarMode.saved,
            _ => ConfigurationSaveBarMode.idle,
          },
          // « Enregistré », pas « Brouillon enregistré » : cette étape est la
          // seule dont la saisie part réellement au serveur.
          savedLabel: l10n.configurationSaved,
          hint: state.missingFields.isEmpty
              ? null
              : l10n.configurationSchoolMissingHint(
                  state.missingFields
                      .map((field) => schoolIdentityFieldLabel(l10n, field))
                      .join(' · '),
                ),
          showBack: false,
          canSave: !blocked && state.isComplete && state.isDirty,
          // Continuer exige d'avoir enregistré : avancer sur une saisie non
          // partie laisserait croire l'étape faite alors que le serveur n'en
          // sait rien.
          canContinue: !blocked && state.isComplete && !state.isDirty,
          onSave: cubit.save,
          onContinue: () => context.read<ConfigurationBloc>().add(
            const ConfigurationContinueRequested(),
          ),
        );
      },
    );
  }
}

/// Barre de pied des étapes 2 à 4 — celles qui ne construisent qu'un brouillon.
///
/// Elle dit « Brouillon enregistré » là où l'étape 1 dit « Enregistré ». Les
/// confondre laisserait croire que la structure et les frais sont partis au
/// serveur, alors que rien ne l'est avant l'activation.
class _DraftStepFooter extends StatelessWidget {
  const _DraftStepFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      builder: (context, state) {
        final bloc = context.read<ConfigurationBloc>();
        final blocked = state.isLoading || state.hasFailure;
        final valid = _isStepValid(state);

        return ConfigurationSaveBar(
          mode: state.justSaved
              ? ConfigurationSaveBarMode.saved
              : ConfigurationSaveBarMode.idle,
          savedLabel: l10n.configurationDraftSaved,
          hint: _hintFor(l10n, state),
          canSave: !blocked && valid,
          canContinue: !blocked && valid,
          onBack: () => bloc.add(const ConfigurationBackRequested()),
          onSave: () => bloc.add(const ConfigurationSaveRequested()),
          onContinue: () => bloc.add(const ConfigurationContinueRequested()),
        );
      },
    );
  }

  bool _isStepValid(ConfigurationState state) {
    return switch (state.step) {
      // L'étape 2 ne demande qu'un intervalle qui tienne debout ; c'est le
      // serveur qui refusera une année déjà existante, et seulement à la
      // simulation.
      ConfigurationStep.academicYear =>
        state.draft.academicYear?.hasValidRange ?? false,
      _ => false,
    };
  }

  /// Ce que l'étape a à dire quand elle bloque.
  ///
  /// L'étape 2 n'en fournit aucun : elle n'a que deux dates, et les nommer
  /// n'ajouterait rien à ce que le champ en erreur montre déjà. C'est le
  /// message par défaut de la barre qui prend le relais.
  String? _hintFor(AppLocalizations l10n, ConfigurationState state) => null;
}
