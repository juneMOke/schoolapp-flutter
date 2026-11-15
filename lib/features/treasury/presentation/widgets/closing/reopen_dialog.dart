import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rouvrir la clôture du jour (R20, promoteur) : un motif obligatoire. Rend
/// `true` si la journée est rouverte.
Future<bool> showReopenDialog(
  BuildContext context, {
  required String registerName,
  required Future<Failure?> Function(String reason) onReopen,
}) async =>
    await EteeloFormDialog.show<bool>(
      context,
      _ReopenDialog(registerName: registerName, onReopen: onReopen),
    ) ??
    false;

class _ReopenDialog extends StatefulWidget {
  final String registerName;
  final Future<Failure?> Function(String reason) onReopen;

  const _ReopenDialog({required this.registerName, required this.onReopen});

  @override
  State<_ReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<_ReopenDialog> {
  final _reason = TextEditingController();
  var _saving = false;
  var _showErrors = false;
  Failure? _failure;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid =>
      _reason.text.trim().length >= CashClosingRules.minJustificationLength;

  Future<void> _submit() async {
    if (_saving) return;
    if (!_valid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onReopen(_reason.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    final VoidCallback? submit = _saving || !_valid ? null : _submit;
    return PopScope(canPop: !_saving, child: _form(l10n, failure, submit));
  }

  Widget _form(AppLocalizations l10n, Failure? failure, VoidCallback? submit) {
    return EteeloFormDialog(
      onSubmit: submit,
      maxWidth: AppDimensions.treasuryRegisterModalMaxWidth,
      eyebrow: l10n.menuTreasury,
      title: l10n.treasuryReopenTitle(widget.registerName),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloTextInput(
            controller: _reason,
            label: l10n.treasuryReopenReason,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 2,
            maxLines: 3,
            required: true,
            enabled: !_saving,
            errorText: _showErrors && !_valid
                ? l10n.treasuryAdjustReasonShort
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.treasuryReopenHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.treasurySaveFailed(l10n.treasuryFailureReason(failure)),
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.secondary(
          label: l10n.treasuryCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.treasuryReopenSave,
          icon: Icons.lock_open_outlined,
          isLoading: _saving,
          onPressed: submit,
          fullWidth: false,
        ),
      ],
    );
  }
}
