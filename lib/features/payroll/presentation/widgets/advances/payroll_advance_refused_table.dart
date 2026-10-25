import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les demandes refusées ou retirées (spec §10, filtre « Refusées ») : closes,
/// montant barré, motif. Une nouvelle demande reste possible.
class PayrollAdvanceRefusedTable extends StatelessWidget {
  final List<PayrollAdvanceRequest> requests;
  final PayrollSnapshot snapshot;

  const PayrollAdvanceRefusedTable({
    super.key,
    required this.requests,
    required this.snapshot,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.payrollColDate,
    AppDimensions.payrollColAmount,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      minWidth: AppDimensions.payrollAdvancesMinWidth,
      widths: _widths,
      endAligned: const {2},
      headers: [
        l10n.payrollColAgent,
        l10n.payrollAdvanceColDecided,
        l10n.payrollAdvanceColAmount,
        l10n.payrollAdvanceColReason,
      ],
      rowCount: requests.length,
      row: (context, index) {
        final request = requests[index];
        final decidedAt = request.decidedAt;
        return EteeloColumnTableRow(
          widths: _widths,
          cells: [
            Text(
              snapshot.member(request.staffMemberId)?.fullName ??
                  request.staffMemberId,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge,
            ),
            Text(
              decidedAt == null ? '—' : PayrollLabels.day(context, decidedAt),
              style: EteeloColumnTableRow.figures(),
            ),
            Text(
              MoneyFormat.format(request.amount),
              textAlign: TextAlign.end,
              style: EteeloColumnTableRow.figures().copyWith(
                decoration: TextDecoration.lineThrough,
                color: AppColors.textMutedAa,
              ),
            ),
            Text(
              request.decisionReason ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
