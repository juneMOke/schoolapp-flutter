import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_profile_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panneau du bulletin : diffuser (PDF, WhatsApp) et ce qui en reste sur
/// la tablette, puis précédent / suivant.
class PayrollPayslipPanel extends StatelessWidget {
  final PayrollState state;
  final PayrollLine line;
  final int index;
  final int count;
  final ValueChanged<int> onStep;

  const PayrollPayslipPanel({
    super.key,
    required this.state,
    required this.line,
    required this.index,
    required this.count,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = PayrollPayslipActions(context);
    final locked = state.view?.phase.isLocked ?? false;
    final traces =
        state.snapshot.shareTraces[PayrollSnapshot.traceKey(
          state.month,
          line.staffMemberId,
        )] ??
        const {};
    final whatsappAt = traces[PayrollShareChannel.whatsapp];
    final pdfAt = traces[PayrollShareChannel.pdf];
    final phone = actions.phoneOf(line.staffMemberId);
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textMutedAa,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locked && !line.frozen)
            PayrollTone.submitted.notice(l10n.payrollPayslipUnsealed),
          EteeloButton.secondary(
            label: l10n.payrollPayslipDownload,
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () => actions.openPdf(line),
          ),
          if (locked) ...[
            const SizedBox(height: AppSpacing.sm),
            EteeloButton.primary(
              label: l10n.payrollPayslipWhatsapp,
              icon: Icons.chat_outlined,
              onPressed: phone == null ? null : () => actions.whatsapp(line),
            ),
            if (phone == null) Text(l10n.payrollPayslipNoPhone, style: muted),
          ],
          if (whatsappAt != null)
            Text(
              l10n.payrollPayslipOpenedWhatsapp(
                PayrollLabels.day(context, whatsappAt),
              ),
              style: muted,
            ),
          if (pdfAt != null)
            Text(
              l10n.payrollPayslipDownloaded(PayrollLabels.day(context, pdfAt)),
              style: muted,
            ),
          if (PermissionGate.allows(context, kPayrollWriteAccess.requires)) ...[
            const SizedBox(height: AppSpacing.sm),
            EteeloButton.ghost(
              label: l10n.payrollProfileEdit,
              icon: Icons.badge_outlined,
              onPressed: () => _editProfile(context),
            ),
          ],
          const Divider(height: AppSpacing.xl),
          if (!locked)
            EteeloButton.ghost(
              label: l10n.payrollPayslipAll,
              icon: Icons.library_books_outlined,
              onPressed: () => actions.openPdf(null),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconButton(
                tooltip: l10n.payrollPayslipPrevious,
                onPressed: index > 0 ? () => onStep(index - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  l10n.payrollPayslipPosition(index + 1, count),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.payrollPayslipNext,
                onPressed: index < count - 1 ? () => onStep(index + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final cubit = context.read<PayrollCubit>();
    final id = line.staffMemberId;
    final profile = await PayrollProfileDialog.show(
      context,
      PayrollProfileDialog(
        name: state.snapshot.member(id)?.fullName ?? id,
        profile: state.snapshot.profiles[id] ?? StaffPayProfile.empty(id),
      ),
    );
    if (profile == null || !context.mounted) return;
    await cubit.perform((commands) => commands.saveProfile(profile));
  }
}
