import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_agent_situations.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Diffuser les bulletins » d'une paie validée : le recueil scellé du
/// mois, puis un WhatsApp par agent — l'application ouvre une conversation
/// à la fois, il n'y a pas d'envoi en lot. Chaque ouverture laisse sa trace.
///
/// Les gestes viennent de l'écran ([onCollection], [onWhatsapp]) : ils
/// s'exécutent dans son contexte, pas dans celui de la modale.
class PayrollDiffuseDialog extends StatelessWidget {
  final VoidCallback onCollection;
  final ValueChanged<PayrollLine> onWhatsapp;
  final String? Function(String staffMemberId) phoneOf;

  const PayrollDiffuseDialog({
    super.key,
    required this.onCollection,
    required this.onWhatsapp,
    required this.phoneOf,
  });

  /// Ouvre la modale sur le cubit de l'écran, qui la tient à jour.
  static Future<void> show(BuildContext context, PayrollDiffuseDialog dialog) =>
      EteeloFormDialog.show<void>(
        context,
        BlocProvider.value(value: context.read<PayrollCubit>(), child: dialog),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PayrollCubit, PayrollState>(
      builder: (context, state) {
        final view = state.view;
        final lines = view == null
            ? const <PayrollLine>[]
            : PayrollAgentSituations.ordered(state.snapshot, view.payable);
        return EteeloFormDialog(
          eyebrow: PayrollLabels.month(context, state.month),
          title: l10n.payrollActionDiffuse,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: EteeloButton.secondary(
                  label: l10n.payrollPayslipAll,
                  icon: Icons.library_books_outlined,
                  onPressed: onCollection,
                  fullWidth: false,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final line in lines)
                _AgentRow(
                  line: line,
                  snapshot: state.snapshot,
                  phone: phoneOf(line.staffMemberId),
                  onWhatsapp: () => onWhatsapp(line),
                ),
            ],
          ),
          actions: [
            EteeloButton.secondary(
              label: l10n.payrollClose,
              onPressed: () => Navigator.of(context).pop(),
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }
}

class _AgentRow extends StatelessWidget {
  final PayrollLine line;
  final PayrollSnapshot snapshot;
  final String? phone;
  final VoidCallback onWhatsapp;

  const _AgentRow({
    required this.line,
    required this.snapshot,
    required this.phone,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final opened =
        snapshot.shareTraces[PayrollSnapshot.traceKey(
          line.month,
          line.staffMemberId,
        )]?[PayrollShareChannel.whatsapp];
    final detail = phone == null
        ? l10n.payrollPayslipNoPhone
        : opened == null
        ? PayrollLabels.money(line.netInCents, line.currency)
        : l10n.payrollPayslipOpenedWhatsapp(PayrollLabels.day(context, opened));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      // Sur un téléphone, le bouton passe sous le nom plutôt que de déborder.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                snapshot.member(line.staffMemberId)?.fullName ??
                    line.staffMemberId,
                style: AppTypography.labelLarge,
              ),
              Text(
                detail,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
            ],
          ),
          EteeloButton.success(
            label: opened == null
                ? l10n.payrollPayslipWhatsapp
                : l10n.payrollAgentWhatsappAgain,
            icon: Icons.chat_outlined,
            size: EteeloButtonSize.compact,
            onPressed: phone == null ? null : onWhatsapp,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
