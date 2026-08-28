import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_amount.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre cartes du récapitulatif : École, Année, Structure, Frais.
///
/// **Toutes les valeurs de structure sortent du plan rendu par la simulation.**
/// L'écran ne recalcule rien — c'est ce qui garantit que ce qu'il promet est ce
/// qui sera écrit.
///
/// La carte « Promoteur » de la maquette a disparu : le compte n'a pas été saisi
/// ici, il existait avant l'assistant.
class SummaryCards extends StatelessWidget {
  final ConfigurationState state;
  final SchoolIdentity? identity;

  const SummaryCards({super.key, required this.state, this.identity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          title: l10n.configurationSummarySchool,
          step: ConfigurationStep.school,
          rows: [
            (l10n.configurationSchoolName, identity?.name),
            (
              l10n.configurationSchoolAddress,
              [
                identity?.address,
                identity?.municipality,
                identity?.district,
                identity?.city,
              ].where((part) => part != null && part.isNotEmpty).join(', '),
            ),
            (l10n.configurationSchoolPhone, identity?.phone),
            (l10n.configurationSchoolEmail, identity?.email),
          ],
        ),
        _Card(
          title: l10n.configurationSummaryYear,
          step: ConfigurationStep.academicYear,
          rows: [
            (l10n.configurationSummaryYear, state.draft.academicYear?.name),
          ],
        ),
        _Card(
          title: l10n.configurationSummaryStructure(state.counts.classrooms),
          step: ConfigurationStep.structure,
          rows: [
            // Une ligne par cycle du PLAN, pas du brouillon : c'est le serveur
            // qui dit ce qu'il ouvrira.
            for (final cycle in state.plan?.cycles ?? const [])
              (
                cycle.name,
                l10n.configurationSummaryCycleLine(
                  cycle.levels.length,
                  cycle.classroomCount,
                ),
              ),
          ],
        ),
        _Card(
          title: l10n.configurationSummaryFees,
          step: ConfigurationStep.fees,
          // Une ligne par frais SAISI, jamais par tarif planifié : un minerval
          // sur vingt niveaux se lirait sinon vingt fois.
          rows: [
            for (final fee in state.draft.fees)
              (
                fee.label,
                '${FeeAmount.display(fee.amountInCents, fee.currency)} · '
                    '${_scopeLabel(l10n, fee)}',
              ),
          ],
        ),
      ],
    );
  }

  static String _scopeLabel(AppLocalizations l10n, FeeInput fee) =>
      fee.appliesTo.scope == FeeScope.allOpenedLevels
      ? l10n.configurationFeeScopeAll
      : l10n.configurationFeeLevelsLabel(
          fee.appliesTo.levelCatalogCodes.length,
        );
}

class _Card extends StatelessWidget {
  final String title;
  final ConfigurationStep step;
  final List<(String, String?)> rows;

  const _Card({required this.title, required this.step, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.read<ConfigurationBloc>().add(
                  ConfigurationStepSelected(step),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.configurationSummaryEdit),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: value == null || value.isEmpty
                        // Jamais un vide silencieux : une valeur manquante se
                        // dit, en rouge, pour qu'on sache où retourner.
                        ? Text(
                            l10n.configurationSummaryMissing,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          )
                        : Text(value, style: AppTypography.labelMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
