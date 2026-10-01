import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/offline/pull_diagnostic.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les flux que le dernier cycle de lecture n'a pas ramenés, un par ligne,
/// avec leur cause.
///
/// Réservé aux super-administrateurs : les noms sont techniques
/// (`finance_payments`, `hr.payrolls`) et le message est celui de l'erreur —
/// de quoi dire au support quel flux se tait, là où le bandeau ne peut que
/// dire qu'« il manque quelque chose ». Le texte est sélectionnable pour être
/// copié tel quel.
class SyncReadDiagnosticsList extends StatelessWidget {
  final List<PullDiagnostic> diagnostics;

  const SyncReadDiagnosticsList({super.key, required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.syncReadDiagnosticsTitle, style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.syncReadDiagnosticsHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final diagnostic in diagnostics)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: SelectableText(
                _line(diagnostic, l10n),
                style: AppTypography.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  String _line(PullDiagnostic diagnostic, AppLocalizations l10n) {
    final cause = switch (diagnostic.kind) {
      PullDiagnosticKind.failed => l10n.syncReadDiagnosticFailed,
      PullDiagnosticKind.blocked => l10n.syncReadDiagnosticBlocked,
      PullDiagnosticKind.forbidden => l10n.syncReadDiagnosticForbidden,
      PullDiagnosticKind.notPulled => l10n.syncReadDiagnosticNotPulled,
    };
    final detail = diagnostic.detail;
    return detail == null || detail.isEmpty
        ? l10n.syncReadDiagnosticLine(diagnostic.resource, cause)
        : l10n.syncReadDiagnosticLineWithDetail(
            diagnostic.resource,
            cause,
            detail,
          );
  }
}
