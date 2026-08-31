import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pied de l'étape 5 : le bloc d'activation.
///
/// Pas de `ConfigurationSaveBar` ici. Cette étape n'enregistre rien — elle
/// écrit, en une transaction, tout ou rien. Lui donner la même barre qu'aux
/// autres ferait passer le geste le plus lourd du parcours pour un
/// enregistrement de plus.
class ConfigurationActivationFooter extends StatelessWidget {
  const ConfigurationActivationFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      builder: (context, state) {
        final identity = context
            .watch<SchoolIdentityFormCubit>()
            .state
            .identity;
        final ready =
            (identity?.isComplete ?? false) &&
            state.hasDatedYear &&
            state.hasClassrooms &&
            state.hasFees;
        // Un échec ferme le geste, comme il ferme la barre des autres étapes.
        // La reprise passe par le bloc d'erreur, jamais par un second clic
        // ici : l'écriture n'est pas idempotente, et un sort inconnu a pu
        // aboutir côté serveur sans que l'écran le sache.
        final blocked =
            state.isActivating || state.isLoading || state.hasFailure;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: state.isActivating
                    ? null
                    : () => context.read<ConfigurationBloc>().add(
                        const ConfigurationBackRequested(),
                      ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(l10n.configurationBack),
              ),
              const Spacer(),
              FilledButton.icon(
                // Actif seulement si les quatre contrôles passent, et fermé
                // pendant l'activation : ce geste n'est pas idempotent, un
                // second appel se ferait refuser en « année déjà existante ».
                onPressed: ready && !blocked
                    ? () => context.read<ConfigurationBloc>().add(
                        const ConfigurationActivationRequested(),
                      )
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppDimensions.minTouchTarget),
                ),
                icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                label: Text(
                  state.isActivating
                      ? l10n.configurationActivating
                      : l10n.configurationActivate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
