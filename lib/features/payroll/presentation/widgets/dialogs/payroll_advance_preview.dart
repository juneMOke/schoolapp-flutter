import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 3 déductions de 20 $ à partir d'octobre », et l'avertissement non
/// bloquant quand l'échéance dépasse la moitié du salaire mensuel (un
/// vacataire à l'heure n'en a pas : aucun avertissement).
class PayrollAdvancePreview extends StatelessWidget {
  final PayrollSnapshot snapshot;
  final SalaryAdvanceDraft draft;

  const PayrollAdvancePreview({
    super.key,
    required this.snapshot,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installment = PayrollMath.floorDiv(
      draft.amount.amountInCents,
      draft.installments,
    );
    final contract = PayrollAdvanceRules.contractFor(
      snapshot,
      draft.staffMemberId,
      draft.firstMonth,
    );
    final monthly = contract?.payMode == StaffPayMode.hourly
        ? null
        : contract?.amount?.amountInCents ?? contract?.bonus?.amountInCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        PayrollTone.validated.notice(
          l10n.payrollAdvancePreview(
            draft.installments,
            PayrollLabels.money(installment, draft.amount.currency),
            PayrollLabels.month(context, draft.firstMonth),
          ),
          icon: Icons.event_repeat,
        ),
        if (monthly != null && installment * 2 > monthly) ...[
          const SizedBox(height: AppSpacing.sm),
          PayrollTone.submitted.notice(
            l10n.payrollAdvanceHeavy,
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ],
    );
  }
}
