import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_amount.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_code_ordering.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Saisie d'un tarif dans les réglages.
///
/// Toute modale à saisie passe par [EteeloDialogBody] : c'est lui qui tient le
/// clavier logiciel, en portrait comme en paysage.
///
/// **Un tarif porte un seul niveau** : le niveau n'est donc pas un champ ici,
/// il est le contexte d'où la modale s'ouvre.
class TariffEditDialog extends StatefulWidget {
  final FeeTariff? initial;
  final List<FeeCodeOption> feeCodes;
  final String levelName;

  const TariffEditDialog({
    super.key,
    required this.feeCodes,
    required this.levelName,
    this.initial,
  });

  @override
  State<TariffEditDialog> createState() => _TariffEditDialogState();
}

/// Ce que la modale rend quand elle est validée.
class TariffEditResult {
  final String feeCode;
  final String label;
  final int amountInCents;
  final String currency;
  final DateTime? dueAt;

  const TariffEditResult({
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
  });
}

class _TariffEditDialogState extends State<TariffEditDialog> {
  late final TextEditingController _label;
  late final TextEditingController _amount;
  String? _feeCode;
  String _currency = 'USD';
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _label = TextEditingController(text: initial?.label ?? '');
    _amount = TextEditingController(
      text: initial == null
          ? ''
          : FeeAmount.inputFromCents(initial.amountInCents),
    );
    _feeCode = initial?.feeCode;
    _currency = initial?.currency ?? 'USD';
    _dueAt = initial?.dueAt;
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _isValid {
    final cents = FeeAmount.centsFromInput(_amount.text);
    return _feeCode != null &&
        _label.text.trim().isNotEmpty &&
        cents != null &&
        cents > 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Le catalogue entier, usuels en tête : aucun code servi n'est retiré.
    final options = [
      ...FeeCodeOrdering.common(widget.feeCodes),
      ...FeeCodeOrdering.others(widget.feeCodes),
    ];

    return Dialog(
      child: EteeloDialogBody(
        header: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initial == null
                          ? l10n.configurationTariffNew
                          : l10n.configurationTariffEdit,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(widget.levelName, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloSelectInput<String>(
              label: l10n.configurationFeeType,
              required: true,
              value: _feeCode,
              items: [
                for (final option in options)
                  EteeloSelectItem<String>(
                    value: option.code,
                    label: option.label,
                  ),
              ],
              onChanged: (value) => setState(() {
                _feeCode = value;
                if (_label.text.trim().isEmpty && value != null) {
                  _label.text = options
                      .firstWhere((option) => option.code == value)
                      .label;
                }
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            EteeloTextInput(
              controller: _label,
              label: l10n.configurationFeeLabel,
              required: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            EteeloTextInput(
              controller: _amount,
              label: l10n.configurationFeeAmount,
              required: true,
              keyboardType: EteeloTextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            EteeloSelectInput<String>(
              label: l10n.configurationFeeCurrency,
              value: _currency,
              items: const [
                EteeloSelectItem<String>(value: 'USD', label: 'USD'),
                EteeloSelectItem<String>(value: 'CDF', label: 'FC'),
              ],
              onChanged: (value) => setState(() => _currency = value ?? 'USD'),
            ),
            const SizedBox(height: AppSpacing.md),
            EteeloDateInput(
              label: l10n.configurationFeeDueAt,
              value: _dueAt,
              onChanged: (value) => setState(() => _dueAt = value),
            ),
          ],
        ),
        footer: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.configurationFeeCancel),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: _isValid
                ? () => Navigator.of(context).pop(
                    TariffEditResult(
                      feeCode: _feeCode!,
                      label: _label.text.trim(),
                      amountInCents: FeeAmount.centsFromInput(_amount.text)!,
                      currency: _currency,
                      dueAt: _dueAt == null
                          ? null
                          : ProvisioningInstant.endOfDayUtc(_dueAt!),
                    ),
                  )
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
            child: Text(l10n.configurationSettingsSave),
          ),
        ],
      ),
    );
  }
}
