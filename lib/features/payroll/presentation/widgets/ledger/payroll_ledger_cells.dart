import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 1 abs », « 2 ret », ou « RAS » — le Pointage du mois ; l'absence n'est
/// retenue que si l'école l'a réglé, par les jours prestés (v2).
class PayrollLedgerSignals extends StatelessWidget {
  final PayrollLine line;

  const PayrollLedgerSignals({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attendance = line.attendance;
    final parts = [
      if (attendance.unjustifiedAbsences > 0)
        (
          l10n.payrollSignalAbsences(attendance.unjustifiedAbsences),
          PayrollTone.alert.ink,
        ),
      if (attendance.lates > 0)
        (l10n.payrollSignalLates(attendance.lates), PayrollTone.submitted.ink),
    ];
    return Tooltip(
      message: l10n.payrollSignalHint,
      child: Text.rich(
        TextSpan(
          children: parts.isEmpty
              ? [
                  TextSpan(
                    text: l10n.payrollSignalNone,
                    style: const TextStyle(color: AppColors.textMutedAa),
                  ),
                ]
              : [
                  for (final (index, (text, color)) in parts.indexed)
                    TextSpan(
                      text: index == 0 ? text : ' · $text',
                      style: TextStyle(color: color),
                    ),
                ],
        ),
        style: AppTypography.bodySmall,
      ),
    );
  }
}

/// Le bout de ligne : le crayon des éléments variables en brouillon, sinon
/// le chevron qui dit que la ligne ouvre la fiche de l'agent.
class PayrollLedgerOpenCell extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  const PayrollLedgerOpenCell({
    super.key,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onEdit = this.onEdit;
    // 48 dp : le thème d'une ligne de tableau ramène un IconButton à 40.
    final target = IconButton.styleFrom(
      minimumSize: const Size.square(AppDimensions.minTouchTarget),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: l10n.payrollLedgerOpenAgent,
          onPressed: onOpen,
          color: AppColors.textSecondary,
          style: target,
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (onEdit != null)
          IconButton(
            tooltip: l10n.payrollVarsTitle,
            onPressed: onEdit,
            style: target,
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
    );
  }
}
