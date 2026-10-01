import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'écran de confrontation d'un refus `PAYROLL_STALE` : ce que la tablette a
/// vu, ce que le serveur a calculé, et les agents qui diffèrent. Une seule
/// issue : synchroniser puis revoir — jamais « valider quand même ». Rend
/// `true` pour synchroniser.
class PayrollStaleDialog extends StatelessWidget {
  final PayrollGesture gesture;

  /// Les lignes que l'écran affiche maintenant, comparées à celles du serveur.
  final List<PayrollLine> current;

  /// Nom d'un agent depuis son identifiant.
  final String Function(String staffMemberId) nameOf;

  const PayrollStaleDialog({
    super.key,
    required this.gesture,
    required this.current,
    required this.nameOf,
  });

  static Future<bool> show(
    BuildContext context, {
    required PayrollGesture gesture,
    required List<PayrollLine> current,
    required String Function(String staffMemberId) nameOf,
  }) async =>
      await EteeloFormDialog.show<bool>(
        context,
        PayrollStaleDialog(gesture: gesture, current: current, nameOf: nameOf),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seen = gesture.expected;
    final server = gesture.serverState;
    final differing = server == null || server.lines.isEmpty
        ? const <String>{}
        : PayrollFingerprinter.differingMembers(
            PayrollFingerprinter.digestLines(current),
            server.lines,
          );
    return EteeloFormDialog(
      title: l10n.payrollStaleTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.payrollStaleBody,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Totals(l10n.payrollStaleSeen, seen)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Totals(l10n.payrollStaleServer, server)),
            ],
          ),
          if (differing.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.payrollStaleMembers(differing.map(nameOf).join(', ')),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollClose,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.payrollStaleRefresh,
          icon: Icons.sync,
          onPressed: () => Navigator.of(context).pop(true),
          fullWidth: false,
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  final String title;
  final PayrollFingerprint? fingerprint;

  const _Totals(this.title, this.fingerprint);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fingerprint = this.fingerprint;
    final style = AppTypography.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (fingerprint == null)
            Text('—', style: style)
          else ...[
            Text(l10n.payrollKpiAgents(fingerprint.lineCount), style: style),
            for (final total in fingerprint.totals)
              Text(
                '${l10n.payrollKpiNet} '
                '${PayrollLabels.money(total.netInCents, total.currency)}',
                style: style,
              ),
          ],
        ],
      ),
    );
  }
}
