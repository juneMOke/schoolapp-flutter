import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_draft_summary.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_fields.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_kind_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La saisie d'un contrat en trois questions : quel statut, ce qu'il paie, à
/// partir de quand — puis, une fois le statut choisi, la ligne qui sera posée.
///
/// Partagée par la page « Nouveau contrat » (et sa correction) et l'étape
/// « Poste & contrat » d'une création : un seul formulaire, une seule
/// validation.
class StaffContractEditor extends StatelessWidget {
  final StaffContractDraft draft;

  /// Les refus à montrer, déjà rédigés — vides tant qu'aucune tentative.
  final Map<StaffContractField, String> errors;
  final ValueChanged<StaffContractDraft Function(StaffContractDraft)> onChanged;

  const StaffContractEditor({
    super.key,
    required this.draft,
    required this.errors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          number: 1,
          title: l10n.staffContractSectionKind,
          error: errors[StaffContractField.kind],
          child: StaffContractKindPicker(
            selected: draft.kind,
            // Re-toucher le statut choisi ne doit pas effacer le mode de
            // paiement déjà saisi.
            onChanged: (kind) {
              if (kind == draft.kind) return;
              onChanged(
                (d) => d.copyWith(kind: () => kind, payMode: () => null),
              );
            },
          ),
        ),
        _Section(
          number: 2,
          title: l10n.staffContractSectionPay,
          child: draft.kind == null
              ? Text(
                  l10n.staffContractPayPending,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : StaffContractPayFields(
                  draft: draft,
                  errors: errors,
                  onChanged: onChanged,
                ),
        ),
        _Section(
          number: 3,
          title: l10n.staffContractSectionPeriod,
          hint: l10n.staffContractPeriodHint,
          child: StaffContractPeriodFields(
            draft: draft,
            errors: errors,
            onChanged: onChanged,
          ),
        ),
        if (draft.kind != null) _Recap(draft: draft),
      ],
    );
  }
}

/// Une question du contrat : son numéro, son titre, et ce qui y répond.
class _Section extends StatelessWidget {
  final int number;
  final String title;
  final String? hint;
  final String? error;
  final Widget child;

  const _Section({
    required this.number,
    required this.title,
    required this.child,
    this.hint,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    final error = this.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: AppSpacing.xl,
                  height: AppSpacing.xl,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                error,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ce qui sera posé, relu avant de valider.
class _Recap extends StatelessWidget {
  final StaffContractDraft draft;

  const _Recap({required this.draft});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffContractTone.of(draft.kind);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: tone.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tone.icon, size: AppSpacing.lg, color: tone.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.staffContractRecap(
                StaffContractDraftSummary.line(l10n, draft),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
