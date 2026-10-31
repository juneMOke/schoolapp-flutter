import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_online_only.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes du catalogue, confiés à la page.
class PayrollDeductionCatalogActions {
  final VoidCallback onAdd;
  final ValueChanged<PayrollDeductionType> onEdit;
  final ValueChanged<PayrollDeductionType> onArchive;
  final ValueChanged<PayrollDeductionType> onRestore;
  final ValueChanged<PayrollDeductionType> onDelete;
  final void Function(PayrollDeductionType type, {required bool up}) onMove;

  const PayrollDeductionCatalogActions({
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
    required this.onMove,
  });
}

enum _Gesture { edit, archive, restore, delete }

/// Une rubrique du catalogue : son libellé, sa fiche résumée, ses gestes.
class PayrollDeductionTypeRow extends StatelessWidget {
  final PayrollDeductionType type;
  final PayrollDeductionCatalogActions? actions;
  final bool canMoveUp;
  final bool canMoveDown;

  const PayrollDeductionTypeRow({
    super.key,
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
    final summary = [
      if (type.code.isNotEmpty) type.code,
      if (type.currency.isNotEmpty)
        type.defaultAmountInCents > 0
            ? l10n.payrollDeductionsDefaultOf(
                PayrollLabels.money(type.defaultAmountInCents, type.currency),
              )
            : l10n.payrollDeductionsNoDefault(type.currency),
    ].join(' · ');
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
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (type.description case final description?)
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
        _Gesture.edit => actions.onEdit(type),
        _Gesture.archive => actions.onArchive(type),
        _Gesture.restore => actions.onRestore(type),
        _Gesture.delete => actions.onDelete(type),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _Gesture.edit,
          child: Text(l10n.payrollDeductionsEdit),
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
