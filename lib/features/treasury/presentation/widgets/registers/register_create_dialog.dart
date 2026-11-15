import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_register_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_amount_field.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/currency_choice.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale enregistre ; rend l'échec, ou `null`.
typedef RegisterCreate =
    Future<Failure?> Function(
      TreasuryCurrency currency,
      String? name,
      int openingAmountInCents,
    );

/// Le résultat d'une création réussie, pour le toast.
class CreatedRegister {
  final String name;
  final TreasuryCurrency currency;
  final int amountInCents;

  const CreatedRegister(this.name, this.currency, this.amountInCents);
}

/// Nouvelle caisse (C2) : la devise (une caisse par devise), le nom (vide ⇒
/// nom automatique) et ce qu'elle détient aujourd'hui (0 accepté).
Future<CreatedRegister?> showRegisterCreateDialog(
  BuildContext context, {
  required List<CashRegister> existing,
  required RegisterCreate onCreate,
}) => EteeloFormDialog.show<CreatedRegister>(
  context,
  _RegisterCreateDialog(existing: existing, onCreate: onCreate),
);

class _RegisterCreateDialog extends StatefulWidget {
  final List<CashRegister> existing;
  final RegisterCreate onCreate;

  const _RegisterCreateDialog({required this.existing, required this.onCreate});

  @override
  State<_RegisterCreateDialog> createState() => _RegisterCreateDialogState();
}

class _RegisterCreateDialogState extends State<_RegisterCreateDialog> {
  late var _currency = CashRegisterRules.availableCurrencies(
    widget.existing,
  ).first;
  final _name = TextEditingController();
  final _amount = TextEditingController();
  var _showErrors = false;
  var _saving = false;
  Failure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  String get _effectiveName => _name.text.trim().isEmpty
      ? CashRegisterRules.defaultName(_currency)
      : _name.text.trim();

  bool get _duplicate =>
      CashRegisterRules.isDuplicateName(_effectiveName, widget.existing) ||
      (_failure is TreasuryRefusalFailure &&
          (_failure! as TreasuryRefusalFailure).refusal ==
              TreasuryRefusal.registerNameTaken);

  Future<void> _save() async {
    final amount = TreasuryAmountField.read(_amount.text, _currency);
    if (amount == null || _duplicate) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final name = _name.text.trim().isEmpty ? null : _name.text.trim();
    final failure = await widget.onCreate(_currency, name, amount);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(
        context,
      ).pop(CreatedRegister(_effectiveName, _currency, amount));
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
    final nameTaken =
        failure is TreasuryRefusalFailure &&
        failure.refusal == TreasuryRefusal.registerNameTaken;
    final VoidCallback? submit = _saving || _duplicate ? null : _save;
    return EteeloFormDialog(
      onSubmit: submit,
      maxWidth: AppDimensions.treasuryRegisterModalMaxWidth,
      eyebrow: l10n.treasuryFormEyebrow,
      title: l10n.treasuryNewRegister,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CurrencyChoice(
            selected: _currency,
            existing: widget.existing,
            onChanged: _saving
                ? null
                : (currency) => setState(() => _currency = currency),
          ),
          const SizedBox(height: AppSpacing.lg),
          EteeloTextInput(
            controller: _name,
            label: l10n.treasuryFormName,
            placeholder: CashRegisterRules.defaultName(_currency),
            enabled: !_saving,
            errorText: _duplicate ? l10n.treasuryDuplicateName : null,
            onChanged: (_) => setState(() {
              if (nameTaken) _failure = null;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          TreasuryAmountField(
            controller: _amount,
            label: l10n.treasuryHoldsToday,
            currency: _currency,
            enabled: !_saving,
            showError: _showErrors,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.treasuryOneCurrencyHint(SchoolTime.today(DateTime.now())),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (failure != null && !nameTaken) ...[
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.treasuryCreate,
          icon: Icons.check,
          isLoading: _saving,
          onPressed: submit,
          fullWidth: false,
        ),
      ],
    );
  }
}
