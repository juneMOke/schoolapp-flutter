import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_amount.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/fee_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 4 — le catalogue des frais.
///
/// Un frais = un type + un montant + une échéance + une **assiette de niveaux**.
/// Jamais de classes : deux classes d'un même niveau paient la même chose.
///
/// ⚠️ **Dissymétrie à ne pas perdre** : un frais saisi produit autant de tarifs
/// que de niveaux dans son assiette. Un minerval sur vingt niveaux apparaît une
/// fois ici, et vingt fois dans le plan.
class FeesStep extends StatefulWidget {
  const FeesStep({super.key});

  @override
  State<FeesStep> createState() => _FeesStepState();
}

class _FeesStepState extends State<FeesStep> {
  /// Formulaire ouvert : en création (`-1`) ou sur le rang d'un frais existant.
  int? _editingIndex;

  bool get _isFormOpen => _editingIndex != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) =>
          previous.draft != current.draft ||
          previous.catalog != current.catalog ||
          previous.feeCodes != current.feeCodes,
      builder: (context, state) {
        final catalog = state.catalog;
        if (catalog == null) return const SizedBox.shrink();

        final bloc = context.read<ConfigurationBloc>();
        final selection = StructureSelection.fromDraft(state.draft, catalog);
        final fees = state.draft.fees;

        // Aucun type servi : la route des types de frais n'est pas bloquante à
        // l'entrée de l'assistant, et on peut donc arriver ici les mains vides.
        // Ouvrir le formulaire montrerait alors une grille de types VIDE, sans
        // un mot — l'agent chercherait la faute de son côté. L'état le dit, et
        // propose la seule action qui change quelque chose.
        if (state.feeCodes.isEmpty) {
          return _FeeTypesUnavailable(
            fees: fees,
            onReload: () => bloc.add(
              const ConfigurationRetryRequested(refreshCatalog: true),
            ),
          );
        }

        void commit(List<FeeInput> next) {
          bloc.add(ConfigurationDraftChanged(state.draft.copyWith(fees: next)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Summary(
              fees: fees,
              // Masqué quand le formulaire est ouvert : deux appels à l'action
              // concurrents feraient hésiter sur celui qui compte.
              onNew: _isFormOpen
                  ? null
                  : () => setState(() => _editingIndex = -1),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_isFormOpen)
              FeeForm(
                key: ValueKey<int>(_editingIndex!),
                catalog: catalog,
                selection: selection,
                feeCodes: state.feeCodes,
                defaultDueAt: state.draft.academicYear?.endDate,
                initial: _editingIndex! >= 0 ? fees[_editingIndex!] : null,
                onCancel: () => setState(() => _editingIndex = null),
                onSubmit: (fee) {
                  final next = [...fees];
                  if (_editingIndex! >= 0) {
                    next[_editingIndex!] = fee;
                  } else {
                    next.add(fee);
                  }
                  commit(next);
                  setState(() => _editingIndex = null);
                  AppSnackBar.showSuccess(
                    context,
                    l10n.configurationFeeSaved(fee.label),
                  );
                },
              ),

            // L'état vide disparaît dès que le formulaire est ouvert : deux
            // messages qui disent la même chose se contredisent à l'usage.
            if (fees.isEmpty && !_isFormOpen)
              EteeloEmptyResult(
                medallionIcon: Icons.receipt_long_rounded,
                accentColor: AppColors.orDoux,
                label: l10n.configurationFeesEmptyTitle,
                description: l10n.configurationFeesEmptyMessage,
                primaryAction: FilledButton.icon(
                  onPressed: () => setState(() => _editingIndex = -1),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.configurationFeesEmptyAction),
                ),
              )
            else
              for (var index = 0; index < fees.length; index++)
                _FeeRow(
                  fee: fees[index],
                  onEdit: _isFormOpen
                      ? null
                      : () => setState(() => _editingIndex = index),
                  onDelete: _isFormOpen
                      ? null
                      : () {
                          final removed = fees[index];
                          commit([...fees]..removeAt(index));
                          // Suppression immédiate, sans dialogue : la ligne
                          // n'est qu'un brouillon local, et le toast la nomme.
                          AppSnackBar.showSuccess(
                            context,
                            l10n.configurationFeeDeleted(removed.label),
                          );
                        },
                ),
          ],
        );
      },
    );
  }
}

/// L'étape 4 sans un seul type de frais servi.
///
/// Les frais déjà saisis restent affichés — un brouillon repris en porte, et
/// les cacher ferait croire à une perte. Ils sont en LECTURE : les modifier
/// demanderait de rechoisir un type, et il n'y en a aucun à choisir.
class _FeeTypesUnavailable extends StatelessWidget {
  final List<FeeInput> fees;
  final VoidCallback onReload;

  const _FeeTypesUnavailable({required this.fees, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(fees: fees, onNew: null),
        const SizedBox(height: AppSpacing.lg),
        EteeloEmptyResult(
          medallionIcon: Icons.price_change_outlined,
          accentColor: AppColors.orDoux,
          label: l10n.configurationFeeTypesUnavailableTitle,
          description: l10n.configurationFeeTypesUnavailableMessage,
          primaryAction: FilledButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.sync_rounded),
            label: Text(l10n.configurationErrorReloadCatalog),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final fee in fees) _FeeRow(fee: fee, onEdit: null, onDelete: null),
      ],
    );
  }
}

/// « n frais définis · Total catalogue : … » et le bouton d'ajout.
class _Summary extends StatelessWidget {
  final List<FeeInput> fees;
  final VoidCallback? onNew;

  const _Summary({required this.fees, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totals = FeeAmount.totalsByCurrency(
      fees.map(
        (fee) => (currency: fee.currency, amountInCents: fee.amountInCents),
      ),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.configurationFeeCount(fees.length),
              style: AppTypography.labelLarge,
            ),
            if (totals.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.configurationFeeCatalogTotal(
                  // Une somme PAR devise, jamais entre elles : 100 USD et
                  // 100 CDF ne font pas 200 de quoi que ce soit.
                  totals.entries
                      .map((entry) => FeeAmount.display(entry.value, entry.key))
                      .join(' · '),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        if (onNew != null)
          FilledButton.icon(
            onPressed: onNew,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.configurationFeeNew),
          ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  final FeeInput fee;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FeeRow({
    required this.fee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = fee.appliesTo.scope == FeeScope.allOpenedLevels
        ? l10n.configurationFeeScopeAll
        : l10n.configurationFeeLevelsLabel(
            fee.appliesTo.levelCatalogCodes.length,
          );
    final dueAt = fee.dueAt;
    final due = dueAt == null
        ? null
        : l10n.configurationFeeDueLabel(_formatDay(dueAt));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowKpi,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(fee.label, style: AppTypography.labelLarge),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      fee.feeCode,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  [scope, ?due].join(' · '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FeeAmount.display(fee.amountInCents, fee.currency),
                style: AppTypography.money.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.configurationFeePerStudent,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

/// `jj/mm/aaaa`, comme partout ailleurs dans l'application.
///
/// Formaté à la main plutôt qu'avec `intl`, qui n'est pas une dépendance
/// déclarée de ce paquet — et qui, sur une date d'échéance déjà portée en UTC,
/// n'apporterait qu'un risque de décalage de jour.
String _formatDay(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
