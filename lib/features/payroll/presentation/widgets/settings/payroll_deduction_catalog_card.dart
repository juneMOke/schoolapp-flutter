import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_online_only.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes du catalogue, confiés à la page.
class PayrollDeductionCatalogActions {
  final VoidCallback onAdd;
  final ValueChanged<PayrollDeductionType> onRename;
  final ValueChanged<PayrollDeductionType> onArchive;
  final ValueChanged<PayrollDeductionType> onRestore;
  final ValueChanged<PayrollDeductionType> onDelete;
  final void Function(PayrollDeductionType type, {required bool up}) onMove;

  const PayrollDeductionCatalogActions({
    required this.onAdd,
    required this.onRename,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
    required this.onMove,
  });
}

/// RH · Paie ▸ Configuration — la carte des rubriques de l'école. Hors de la
/// barre d'enregistrement : chaque geste s'écrit seul. [actions] nul : l'économe
/// consulte.
class PayrollDeductionCatalogCard extends StatelessWidget {
  final List<PayrollDeductionType> catalog;
  final PayrollDeductionCatalogActions? actions;

  const PayrollDeductionCatalogCard({
    super.key,
    required this.catalog,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = catalog.where((type) => !type.archived).toList();
    final archived = catalog.where((type) => type.archived).toList();
    final actions = this.actions;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: BiToneSectionCard(
        title: l10n.payrollDeductionsTitle,
        subtitle: l10n.payrollDeductionsSubtitle,
        icon: Icons.playlist_remove_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (active.isEmpty)
              Text(
                l10n.payrollDeductionsEmpty,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            for (final (index, type) in active.indexed)
              _TypeRow(
                type: type,
                actions: actions,
                canMoveUp: index > 0,
                canMoveDown: index < active.length - 1,
              ),
            if (actions != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: EteeloButton.secondary(
                  label: l10n.payrollDeductionsAdd,
                  icon: Icons.add,
                  onPressed: active.length < PayrollDeductionType.maxActive
                      ? actions.onAdd
                      : null,
                  fullWidth: false,
                ),
              ),
              if (active.length >= PayrollDeductionType.maxActive) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.payrollRuleDeductionTypeLimit,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.payrollDeductionsArchivedTitle,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              for (final type in archived)
                _TypeRow(type: type, actions: actions),
            ],
          ],
        ),
      ),
    );
  }
}

enum _Gesture { rename, archive, restore, delete }

class _TypeRow extends StatelessWidget {
  final PayrollDeductionType type;
  final PayrollDeductionCatalogActions? actions;
  final bool canMoveUp;
  final bool canMoveDown;

  const _TypeRow({
    required this.type,
    required this.actions,
    this.canMoveUp = false,
    this.canMoveDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = this.actions;
    final note = switch (type.syncState) {
      RecordSyncState.failed => PayrollLabels.serverRefusal(
        l10n,
        type.syncErrorCode,
      ),
      RecordSyncState.pending => l10n.payrollDeductionsPending,
      RecordSyncState.synced => null,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.minTouchTarget,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: type.archived
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: AppTypography.bodySmall.copyWith(
                      color: type.syncState == RecordSyncState.failed
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null && !type.archived) ...[
            IconButton(
              tooltip: l10n.payrollDeductionsMoveUp,
              icon: const Icon(Icons.arrow_upward),
              onPressed: canMoveUp
                  ? () => actions.onMove(type, up: true)
                  : null,
            ),
            IconButton(
              tooltip: l10n.payrollDeductionsMoveDown,
              icon: const Icon(Icons.arrow_downward),
              onPressed: canMoveDown
                  ? () => actions.onMove(type, up: false)
                  : null,
            ),
          ],
          if (actions != null)
            PayrollOnlineOnly(
              builder: (context, online) =>
                  _GestureMenu(type: type, online: online, actions: actions),
            ),
        ],
      ),
    );
  }
}

class _GestureMenu extends StatelessWidget {
  final PayrollDeductionType type;
  final bool online;
  final PayrollDeductionCatalogActions actions;

  const _GestureMenu({
    required this.type,
    required this.online,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDelete = online || !type.serverKnown;
    return PopupMenuButton<_Gesture>(
      tooltip: l10n.payrollDeductionsActions,
      onSelected: (gesture) => switch (gesture) {
        _Gesture.rename => actions.onRename(type),
        _Gesture.archive => actions.onArchive(type),
        _Gesture.restore => actions.onRestore(type),
        _Gesture.delete => actions.onDelete(type),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _Gesture.rename,
          child: Text(l10n.payrollDeductionsRename),
        ),
        if (type.archived)
          PopupMenuItem(
            value: _Gesture.restore,
            child: Text(l10n.payrollDeductionsRestore),
          )
        else
          PopupMenuItem(
            value: _Gesture.archive,
            child: Text(l10n.payrollDeductionsArchive),
          ),
        PopupMenuItem(
          value: _Gesture.delete,
          enabled: canDelete,
          child: Text(
            canDelete
                ? l10n.payrollDeductionsDelete
                : l10n.payrollDeductionsDeleteOffline,
          ),
        ),
      ],
    );
  }
}
