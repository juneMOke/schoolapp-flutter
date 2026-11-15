import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_register_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_amount_field.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/adjust_amount_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale envoie : le montant actuel **qu'elle a montré**, le
/// nouveau, le motif. Rend l'ajustement, ou l'échec.
typedef RegisterAdjust =
    Future<Either<Failure, CashAdjustment>> Function(
      int shownExpectedInCents,
      int newAmountInCents,
      String reason,
    );

/// Ajuster le montant détenu (C3) : un mouvement daté d'aujourd'hui, signé et
/// motivé ; le passé n'est jamais réécrit (R14).
Future<CashAdjustment?> showRegisterAdjustDialog(
  BuildContext context, {
  required RegisterConfig config,
  required RegisterAdjust onAdjust,
}) => EteeloFormDialog.show<CashAdjustment>(
  context,
  _RegisterAdjustDialog(config: config, onAdjust: onAdjust),
);

class _RegisterAdjustDialog extends StatefulWidget {
  final RegisterConfig config;
  final RegisterAdjust onAdjust;

  const _RegisterAdjustDialog({required this.config, required this.onAdjust});

  @override
  State<_RegisterAdjustDialog> createState() => _RegisterAdjustDialogState();
}

class _RegisterAdjustDialogState extends State<_RegisterAdjustDialog> {
  /// Le montant actuel montré. Il change si le serveur répond qu'il a bougé :
  /// l'écran montre alors le nouveau, et c'est lui qui repart.
  late var _current = widget.config.balanceInCents;
  late final _amount = TextEditingController(
    text: TreasuryAmountField.formatForInput(_current),
  );
  final _reason = TextEditingController();
  var _showErrors = false;
  var _saving = false;
  Failure? _failure;
  int? _movedFrom;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  CashRegister get _register => widget.config.register;

  int? get _newAmount =>
      TreasuryAmountField.read(_amount.text, _register.currency);

  bool get _valid => CashRegisterRules.canAdjust(
    currency: _register.currency,
    currentInCents: _current,
    newAmountInCents: _newAmount,
    reason: _reason.text,
    closedToday: widget.config.closedToday,
  );

  Future<void> _save() async {
    final next = _newAmount;
    if (!_valid || next == null) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final result = await widget.onAdjust(_current, next, _reason.text);
    if (!mounted) return;
    result.fold((failure) => _refused(failure), Navigator.of(context).pop);
  }

  void _refused(Failure failure) {
    final serverExpected =
        failure is TreasuryRefusalFailure &&
            failure.refusal == TreasuryRefusal.expectedChanged
        ? failure.serverExpectedInCents
        : null;
    setState(() {
      _saving = false;
      if (serverExpected != null) {
        // Rien n'est enregistré : on montre le nouveau montant actuel, et la
        // saisie de l'utilisateur reste telle quelle pour qu'il la relise.
        _movedFrom = _current;
        _current = serverExpected;
        _failure = null;
      } else {
        _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = _register.currency;
    final failure = _failure;
    final movedFrom = _movedFrom;
    final closed = widget.config.closedToday;
    final reasonTooShort =
        _showErrors && !CashRegisterRules.isReasonValid(_reason.text);
    final VoidCallback? submit = _saving || !_valid ? null : _save;
    return EteeloFormDialog(
      onSubmit: submit,
      maxWidth: AppDimensions.treasuryRegisterModalMaxWidth,
      eyebrow: l10n.treasuryFormEyebrow,
      title: l10n.treasuryAdjustTitle(_register.name),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdjustAmountSummary(
            currency: currency,
            currentInCents: _current,
            newAmountInCents: _newAmount,
          ),
          if (movedFrom != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Message(
              text: l10n.treasuryAdjustExpectedChanged(
                TreasuryFormat.money(movedFrom, currency),
                TreasuryFormat.money(_current, currency),
              ),
              color: AppColors.financeCrossedAccent,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TreasuryAmountField(
            controller: _amount,
            label: l10n.treasuryAdjustActual,
            currency: currency,
            enabled: !_saving && !closed,
            showError: _showErrors,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          EteeloTextInput(
            controller: _reason,
            label: l10n.treasuryAdjustReason,
            placeholder: l10n.treasuryAdjustReasonHint,
            required: true,
            enabled: !_saving && !closed,
            errorText: reasonTooShort ? l10n.treasuryAdjustReasonShort : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final motif in [
                l10n.treasuryMotif1,
                l10n.treasuryMotif2,
                l10n.treasuryMotif3,
                l10n.treasuryMotif4,
              ])
                ActionChip(
                  label: Text(motif),
                  // Une suggestion de motif remplace le texte (§14 bis).
                  onPressed: _saving || closed
                      ? null
                      : () => setState(() => _reason.text = motif),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (closed)
            _Message(
              text: l10n.treasuryAdjustClosedWarning,
              color: AppColors.financeCrossedAccent,
            )
          else
            _Message(
              text: l10n.treasuryAdjustHint,
              color: AppColors.textSecondary,
            ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Message(
              text: l10n.treasurySaveFailed(
                l10n.treasuryFailureReason(failure),
              ),
              color: AppColors.error,
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.secondary(
          label: l10n.treasuryCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.treasuryAdjustSave,
          icon: Icons.check,
          isLoading: _saving,
          onPressed: submit,
          fullWidth: false,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Color color;

  const _Message({required this.text, required this.color});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.bodySmall.copyWith(color: color));
}
