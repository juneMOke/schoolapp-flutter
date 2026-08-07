import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Pastille d'état du solde affichée dans l'AppBar sombre (spec §06).
///
/// Dû → accent rouge + « {solde} dû ». À jour → accent vert + « À jour ».
class FacturationBalancePill extends StatelessWidget {
  final bool hasBalance;
  final String label;

  const FacturationBalancePill({
    super.key,
    required this.hasBalance,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return StudentDetailAppBarPill(
      accent: hasBalance ? AppColors.feeStatusDue : AppColors.feeStatusPaid,
      icon: hasBalance
          ? Icons.account_balance_wallet_outlined
          : Icons.check_circle_outline,
      label: label,
      alert: hasBalance,
    );
  }
}
