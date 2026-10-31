import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
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

/// Le tableau des rubriques : code, libellé et description, devise, montant
/// par défaut, et le menu des gestes au bout de la ligne. [actions] nul :
/// l'économe consulte, sans colonne de menu.
class PayrollDeductionTable extends StatelessWidget {
  final List<PayrollDeductionType> types;
  final PayrollDeductionCatalogActions? actions;

  const PayrollDeductionTable({
    super.key,
    required this.types,
    required this.actions,
  });

  List<double?> get _widths => [
    AppDimensions.payrollDeductionColCode,
    null,
    AppDimensions.payrollDeductionColCurrency,
    AppDimensions.payrollDeductionColDefault,
    if (actions != null) AppDimensions.minTouchTarget,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: AppDimensions.payrollDeductionTableMinWidth,
      widths: _widths,
      endAligned: const {3},
      headers: [
        l10n.payrollDeductionsCode,
        l10n.payrollDeductionsLabel,
        l10n.payrollDeductionsCurrency,
        l10n.payrollDeductionsColDefault,
        if (actions != null) '',
      ],
      rowCount: types.length,
      row: (context, index) => _row(context, index),
    );
  }

  /// Rend directement une `EteeloColumnTableRow` : enveloppée, elle ne
  /// deviendrait pas une carte sur téléphone.
  EteeloColumnTableRow _row(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final type = types[index];
    final actions = this.actions;
    final ink = type.archived ? AppColors.textSecondary : null;
    final note = switch (type.syncState) {
      RecordSyncState.failed => PayrollLabels.serverRefusal(
        l10n,
        type.syncErrorCode,
      ),
      RecordSyncState.pending => l10n.payrollDeductionsPending,
      RecordSyncState.synced => null,
    };
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    return EteeloColumnTableRow(
      widths: _widths,
      cells: [
        Text(
          type.code.isEmpty ? '—' : type.code,
          style: AppTypography.labelLarge.copyWith(color: ink),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.label,
              style: AppTypography.bodyMedium.copyWith(color: ink),
            ),
            if (type.description case final description?)
              Text(description, style: muted),
            if (note != null)
              Text(
                note,
                style: type.syncState == RecordSyncState.failed
                    ? muted.copyWith(color: AppColors.error)
                    : muted,
              ),
          ],
        ),
        Text(
          type.currency.isEmpty ? '—' : type.currency,
          style: AppTypography.bodyMedium.copyWith(color: ink),
        ),
        Text(
          type.defaultAmountInCents > 0
              ? PayrollLabels.money(type.defaultAmountInCents, type.currency)
              : '—',
          textAlign: TextAlign.end,
          style: EteeloColumnTableRow.figures(color: ink),
        ),
        if (actions != null)
          PayrollOnlineOnly(
            builder: (context, online) => _GestureMenu(
              type: type,
              online: online,
              actions: actions,
              canMoveUp: !type.archived && index > 0,
              canMoveDown: !type.archived && index < types.length - 1,
            ),
          ),
      ],
    );
  }
}

enum _Gesture { edit, moveUp, moveDown, archive, restore, delete }

class _GestureMenu extends StatelessWidget {
  final PayrollDeductionType type;
  final bool online;
  final PayrollDeductionCatalogActions actions;
  final bool canMoveUp;
  final bool canMoveDown;

  const _GestureMenu({
    required this.type,
    required this.online,
    required this.actions,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDelete = online || !type.serverKnown;
    return PopupMenuButton<_Gesture>(
      tooltip: l10n.payrollDeductionsActions,
      onSelected: (gesture) => switch (gesture) {
        _Gesture.edit => actions.onEdit(type),
        _Gesture.moveUp => actions.onMove(type, up: true),
        _Gesture.moveDown => actions.onMove(type, up: false),
        _Gesture.archive => actions.onArchive(type),
        _Gesture.restore => actions.onRestore(type),
        _Gesture.delete => actions.onDelete(type),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _Gesture.edit,
          child: Text(l10n.payrollDeductionsEdit),
        ),
        if (!type.archived) ...[
          PopupMenuItem(
            value: _Gesture.moveUp,
            enabled: canMoveUp,
            child: Text(l10n.payrollDeductionsMoveUp),
          ),
          PopupMenuItem(
            value: _Gesture.moveDown,
            enabled: canMoveDown,
            child: Text(l10n.payrollDeductionsMoveDown),
          ),
          PopupMenuItem(
            value: _Gesture.archive,
            child: Text(l10n.payrollDeductionsArchive),
          ),
        ] else
          PopupMenuItem(
            value: _Gesture.restore,
            child: Text(l10n.payrollDeductionsRestore),
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
