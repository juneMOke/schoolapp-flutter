import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le matricule d'un agent, ou « Matricule en attente » tant que le serveur
/// ne l'a pas attribué. Affiché tel quel, jamais construit ni découpé.
class StaffNumberText extends StatelessWidget {
  final String? staffNumber;

  const StaffNumberText({super.key, required this.staffNumber});

  @override
  Widget build(BuildContext context) {
    final number = staffNumber;
    return Text(
      number ?? AppLocalizations.of(context)!.staffNumberPending,
      style: AppTypography.labelSmall.copyWith(
        fontFamily: 'monospace',
        color: number == null
            ? AppColors.staffPartialInk
            : AppColors.textMutedAa,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// « Fonction · Matière, Matière » — ce que fait l'agent à l'école.
class StaffRoleText extends StatelessWidget {
  final StaffMember member;

  const StaffRoleText({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final job = member.jobTitle?.trim() ?? '';
    final parts = [
      if (job.isNotEmpty) job,
      if (member.branches.isNotEmpty) member.branches.join(', '),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
