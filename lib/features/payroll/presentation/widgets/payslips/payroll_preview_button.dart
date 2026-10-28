import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_online_only.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Bulletin provisoire (PDF) » d'un brouillon (P8) : rendu par le serveur,
/// donc en ligne seulement — désactivé hors ligne avec son message, et occupé
/// le temps de l'envoi de la file puis du rendu : un second toucher ne
/// relance rien.
class PayrollPreviewButton extends StatefulWidget {
  final PayrollLine line;

  /// Parmi d'autres boutons d'une ligne : à sa largeur, pas à celle du
  /// panneau.
  final bool inline;

  const PayrollPreviewButton({
    super.key,
    required this.line,
    this.inline = false,
  });

  @override
  State<PayrollPreviewButton> createState() => _PayrollPreviewButtonState();
}

class _PayrollPreviewButtonState extends State<PayrollPreviewButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    await PayrollPayslipActions(context).openPreview(widget.line);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PayrollOnlineOnly(
      builder: (context, online) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.inline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          EteeloButton.secondary(
            label: l10n.payrollPayslipDownloadProvisional,
            icon: Icons.picture_as_pdf_outlined,
            isLoading: _busy,
            onPressed: online ? _open : null,
            fullWidth: !widget.inline,
            size: widget.inline
                ? EteeloButtonSize.regular
                : EteeloButtonSize.compact,
          ),
          if (!online)
            Text(
              l10n.payrollPayslipOnlineOnly,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
        ],
      ),
    );
  }
}
