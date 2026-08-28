import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/school_identity_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/settings_structure_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Onglets des réglages, après mise en service.
enum ConfigurationSettingsTab { identity, structure, fees }

/// Les réglages réouvrables.
///
/// **Mêmes widgets que l'assistant, chrome différent** : l'onglet Identité est
/// exactement le widget de l'étape 1. Dupliquer le formulaire aurait produit
/// deux écrans qui divergent au premier amendement, sur des champs qui figurent
/// ensuite sur les attestations.
///
/// **Il n'existe pas de statut sur l'école.** Une année courante avec des
/// classes *est* la mise en service : le bandeau se déduit du contexte
/// académique, et l'écran se réduit à un état vide si celui-ci ne rend rien.
///
/// L'onglet Année a disparu : le paramétrage ne se rejoue pas, et rien d'autre
/// ne permet d'amender une année ouverte.
class ConfigurationSettingsPage extends StatefulWidget {
  const ConfigurationSettingsPage({super.key});

  @override
  State<ConfigurationSettingsPage> createState() =>
      _ConfigurationSettingsPageState();
}

class _ConfigurationSettingsPageState extends State<ConfigurationSettingsPage> {
  ConfigurationSettingsTab _tab = ConfigurationSettingsTab.identity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider<SchoolIdentityFormCubit>(
      create: (_) => getIt<SchoolIdentityFormCubit>()..load(),
      child: Builder(
        builder: (context) {
          final academicContext = context
              .watch<AcademicYearContextBloc>()
              .state
              .context;

          return AppPageBackground(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: academicContext == null
                  ? EteeloEmptyResult(
                      medallionIcon: Icons.event_busy_rounded,
                      label: l10n.configurationSettingsNoYear,
                      description: l10n.splashNotProvisionedMessage,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StateBanner(
                          schoolName: context
                              .watch<SchoolIdentityFormCubit>()
                              .state
                              .identity
                              ?.name,
                          yearName: academicContext.academicYear.name,
                          levels: academicContext.schoolLevelGroups.fold(
                            0,
                            (total, bundle) => total + bundle.levels.length,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SegmentedTabFilter<ConfigurationSettingsTab>(
                          selected: _tab,
                          onSelected: (tab) => setState(() => _tab = tab),
                          options: [
                            SegmentedTabOption(
                              value: ConfigurationSettingsTab.identity,
                              label: l10n.configurationSettingsTabIdentity,
                            ),
                            SegmentedTabOption(
                              value: ConfigurationSettingsTab.structure,
                              label:
                                  '${l10n.configurationSettingsTabStructure} · '
                                  '${l10n.configurationSettingsReadOnly}',
                            ),
                            SegmentedTabOption(
                              value: ConfigurationSettingsTab.fees,
                              label: l10n.configurationSettingsTabFees,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: SingleChildScrollView(
                            child: switch (_tab) {
                              // Le MÊME widget que l'étape 1 de l'assistant.
                              ConfigurationSettingsTab.identity =>
                                const _IdentityTab(),
                              ConfigurationSettingsTab.structure =>
                                SettingsStructureView(
                                  bundles: academicContext.schoolLevelGroups,
                                ),
                              ConfigurationSettingsTab.fees =>
                                SettingsStructureView(
                                  bundles: academicContext.schoolLevelGroups,
                                  showTariffs: true,
                                  academicYearId:
                                      academicContext.academicYear.id,
                                ),
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// L'onglet Identité : l'étape 1 de l'assistant, avec son propre pied.
///
/// `onNext = onSave` : la barre reste, mais elle enregistre au lieu d'avancer.
class _IdentityTab extends StatelessWidget {
  const _IdentityTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      listenWhen: (previous, current) =>
          !previous.justSaved && current.justSaved,
      listener: (context, state) =>
          AppSnackBar.showSuccess(context, l10n.configurationSettingsSaved),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SchoolIdentityStep(),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    state.isComplete &&
                        state.isDirty &&
                        state.status != SchoolIdentityFormStatus.saving
                    ? context.read<SchoolIdentityFormCubit>().save
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppDimensions.minTouchTarget),
                ),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.configurationSettingsSave),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bandeau « école en service ».
class _StateBanner extends StatelessWidget {
  final String? schoolName;
  final String yearName;
  final int levels;

  const _StateBanner({
    required this.schoolName,
    required this.yearName,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5EF),
        borderRadius: AppRadius.brCard,
        border: Border.all(color: const Color(0xFFBFD8C6)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.configurationSettingsInService(schoolName ?? ''),
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                // Recalculé depuis le contexte, jamais figé : un chiffre gelé
                // au moment de l'activation mentirait dès la classe suivante.
                l10n.configurationSettingsSummary(yearName, 0, levels),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Tooltip(
            message: l10n.configurationSettingsNextYearTooltip,
            child: OutlinedButton.icon(
              // Désactivé en V1, et l'infobulle dit pourquoi. L'assistant ne se
              // rejoue pas : le serveur refuserait à l'étape 5, sur une année
              // déjà ouverte. Il faudra un geste serveur dédié.
              onPressed: null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.minTouchTarget),
              ),
              icon: const Icon(Icons.event_repeat_rounded, size: 18),
              label: Text(l10n.configurationSettingsNextYear),
            ),
          ),
        ],
      ),
    );
  }
}
