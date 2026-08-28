import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/academic_year_proposal.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_field_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 2 — l'année académique.
///
/// Une année est proposée d'après la date du jour (bascule au 1er juillet), le
/// promoteur ajuste les dates au calendrier de son établissement.
///
/// **Aucun identifiant n'est affiché.** Il n'en existe pas avant l'activation,
/// et celui qu'elle rend est un UUID : montrer un `AY_2027` dérivé de l'année
/// promettrait une clé que la base ne portera jamais.
class AcademicYearStep extends StatelessWidget {
  /// Injectable pour le test : la proposition dépend du jour.
  final DateTime? today;

  const AcademicYearStep({super.key, this.today});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = today ?? DateTime.now();

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) =>
          previous.draft.academicYear != current.draft.academicYear,
      builder: (context, state) {
        final year =
            state.draft.academicYear ?? AcademicYearProposal.forDate(now);
        final pristine = AcademicYearProposal.isPristine(year, now);
        final validRange = year.hasValidRange;

        void update(AcademicYearInput next) {
          context.read<ConfigurationBloc>().add(
            ConfigurationDraftChanged(
              state.draft.copyWith(academicYear: next),
              // La structure ne dépend pas des dates : simuler à chaque coup de
              // calendrier ferait un aller-retour pour un plan identique. La
              // simulation reprend à l'étape suivante, où elle a du sens.
              simulate: false,
            ),
          );
        }

        return BiToneSectionCard(
          title: l10n.configurationYearSectionTitle,
          subtitle: l10n.configurationYearSectionSubtitle,
          icon: Icons.event_rounded,
          accentColor: AppColors.bleuArdoise,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YearBanner(
                label: year.name,
                pristine: pristine,
                onRestore: pristine
                    ? null
                    : () => update(AcademicYearProposal.forDate(now)),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConfigurationFieldGrid(
                wideColumns: 3,
                children: [
                  EteeloDateInput(
                    label: l10n.configurationYearStart,
                    required: true,
                    value: year.startDate,
                    onChanged: (value) {
                      if (value == null) return;
                      update(
                        year.copyWith(
                          startDate: ProvisioningInstant.startOfDayUtc(value),
                        ),
                      );
                    },
                  ),
                  EteeloDateInput(
                    label: l10n.configurationYearEnd,
                    required: true,
                    value: year.endDate,
                    errorText: validRange
                        ? null
                        : l10n.configurationYearRangeError,
                    onChanged: (value) {
                      if (value == null) return;
                      update(
                        year.copyWith(
                          endDate: ProvisioningInstant.startOfDayUtc(value),
                        ),
                      );
                    },
                  ),
                  _Duration(
                    start: year.startDate,
                    end: year.endDate,
                    valid: validRange,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.configurationYearPeriodsNote,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Le libellé de l'année, en grand, avec son origine.
class _YearBanner extends StatelessWidget {
  final String label;
  final bool pristine;
  final VoidCallback? onRestore;

  const _YearBanner({
    required this.label,
    required this.pristine,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        color: AppColors.bleuArdoiseSoft,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Text(
            label,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pristine ? Icons.auto_awesome_rounded : Icons.edit_rounded,
                size: 15,
                color: pristine ? AppColors.vertSavane : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                pristine
                    ? l10n.configurationYearProposed
                    : l10n.configurationYearEdited,
                style: AppTypography.bodySmall.copyWith(
                  color: pristine ? AppColors.vertSavane : AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (onRestore != null)
            TextButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(l10n.configurationYearRestore),
            ),
        ],
      ),
    );
  }
}

/// Durée indicative, ou l'avertissement quand l'intervalle est inversé.
class _Duration extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final bool valid;

  const _Duration({
    required this.start,
    required this.end,
    required this.valid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = AcademicYearProposal.monthsBetween(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.configurationYearDuration,
          style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              valid ? Icons.schedule_rounded : Icons.warning_amber_rounded,
              size: 16,
              color: valid ? AppColors.textMuted : AppColors.error,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                valid
                    ? l10n.configurationYearDurationValue(months)
                    : l10n.configurationYearRangeError,
                style: AppTypography.bodyMedium.copyWith(
                  color: valid ? AppColors.textPrimary : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
