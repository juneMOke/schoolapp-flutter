import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/school_identity_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_activation_footer.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_save_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de pied de l'étape courante.
///
/// L'étape 1 y parle un autre langage que les suivantes : elle écrit vraiment,
/// donc elle dit « Enregistré » là où les autres diront « Brouillon
/// enregistré ». C'est la seule trace visible d'une distinction qui décide de
/// ce qui survit à la fermeture de l'application.
class ConfigurationStepFooter extends StatelessWidget {
  const ConfigurationStepFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) => previous.step != current.step,
      builder: (context, state) => switch (state.step) {
        ConfigurationStep.school => const _SchoolStepFooter(),
        ConfigurationStep.academicYear => const _DraftStepFooter(),
        ConfigurationStep.structure => const _DraftStepFooter(),
        ConfigurationStep.fees => const _DraftStepFooter(),
        // L'étape 5 n'a pas de barre d'enregistrement : elle porte son propre
        // bloc d'activation, qui n'enregistre pas — il écrit.
        ConfigurationStep.activation => const ConfigurationActivationFooter(),
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
      // L'étape 3 se juge sur le PLAN, pas sur les cases cochées : c'est le
      // serveur qui dit combien de classes seront créées, et c'est ce
      // chiffre-là qui engage.
      ConfigurationStep.structure => state.counts.classrooms > 0,
      // Au moins un frais saisi. Le sous-formulaire ouvert bloque de son côté,
      // depuis l'étape elle-même : le bloc ne le connaît pas, et n'a pas à le
      // connaître — c'est un état d'écran, pas de brouillon.
      ConfigurationStep.fees => state.draft.fees.isNotEmpty,
      _ => false,
    };
  }

  /// Ce que l'étape a à dire quand elle bloque.
  ///
  /// L'étape 2 n'en fournit aucun : elle n'a que deux dates, et les nommer
  /// n'ajouterait rien à ce que le champ en erreur montre déjà. C'est le
  /// message par défaut de la barre qui prend le relais.
  String? _hintFor(AppLocalizations l10n, ConfigurationState state) {
    return switch (state.step) {
      // Le seul endroit où l'engagement est chiffré avant l'activation.
      ConfigurationStep.structure =>
        state.counts.classrooms > 0
            ? l10n.configurationStructureHint(state.counts.classrooms)
            : l10n.configurationStructureEmptyHint,
      _ => null,
    };
  }
}
