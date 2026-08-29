import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/academic_year_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/activation_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/fees_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/school_identity_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/structure_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_error_view.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_step_skeleton.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Le contenu de l'étape, ou ce qui le remplace.
///
/// Ordre des états, et il compte : chargement d'abord (squelettes, jamais un
/// spinner), erreur ensuite (dans la carte, jamais seulement en toast), contenu
/// en dernier. Afficher le contenu par-dessus une erreur laisserait croire à des
/// données fraîches.
class ConfigurationStepContent extends StatelessWidget {
  const ConfigurationStepContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) =>
          previous.step != current.step ||
          previous.status != current.status ||
          previous.failure != current.failure,
      builder: (context, state) {
        if (state.isLoading) {
          return ConfigurationStepSkeleton(step: state.step);
        }

        if (state.failure case final failure? when state.hasFailure) {
          final bloc = context.read<ConfigurationBloc>();
          final kind = classifyConfigurationFailure(failure);

          return ConfigurationErrorView(
            failure: failure,
            onRetry: () => bloc.add(const ConfigurationRetryRequested()),
            // Le 422 « code inconnu » est le seul cas où recharger le catalogue
            // change quelque chose : ailleurs, ce serait un appel de plus pour
            // rien.
            onReloadCatalog: kind == ConfigurationErrorKind.staleCatalog
                ? () => bloc.add(
                    const ConfigurationRetryRequested(refreshCatalog: true),
                  )
                : null,
            onBackToYear: kind == ConfigurationErrorKind.yearAlreadyExists
                ? () => bloc.add(const ConfigurationYearConflictAcknowledged())
                : null,
            onSignIn: kind == ConfigurationErrorKind.session
                ? () => context.goNamed(AppRoutesNames.login)
                : null,
          );
        }

        return switch (state.step) {
          ConfigurationStep.school => const SchoolIdentityStep(),
          ConfigurationStep.academicYear => const AcademicYearStep(),
          ConfigurationStep.structure => const StructureStep(),
          ConfigurationStep.fees => const FeesStep(),
          ConfigurationStep.activation => const ActivationStep(),
        };
      },
    );
  }
}
