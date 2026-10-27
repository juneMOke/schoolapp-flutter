import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_sheet.dart';

/// Le panneau du mois choisi : son bulletin, tel qu'il s'imprime.
class PayrollAgentMonthPanel extends StatelessWidget {
  final PayrollSnapshot snapshot;
  final PayrollAgentMonth month;

  const PayrollAgentMonthPanel({
    super.key,
    required this.snapshot,
    required this.month,
  });

  @override
  Widget build(BuildContext context) => EteeloPanelCard(
    child: Center(
      child: PayrollPayslipSheet(
        content: PayrollPayslipContent.of(
          context,
          snapshot: snapshot,
          view: month.view,
          line: month.line,
        ),
      ),
    ),
  );
}
