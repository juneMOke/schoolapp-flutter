import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_amount.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_code_ordering.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_field_grid.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/fee_scope_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Formulaire d'un frais : un type, un montant, une échéance, une assiette.
///
/// Ouvert, il **domine visuellement la liste** (bordure et ombre ambre) : c'est
/// ce qui dit qu'une saisie est en cours, et pourquoi « Continuer » attend.
class FeeForm extends StatefulWidget {
  final ProvisioningCatalog catalog;
  final StructureSelection selection;
  final List<FeeCodeOption> feeCodes;

  /// Échéance proposée : la fin de l'année académique.
  final DateTime? defaultDueAt;

  /// Frais en cours de modification, `null` pour une création.
  final FeeInput? initial;

  final ValueChanged<FeeInput> onSubmit;
  final VoidCallback onCancel;

  const FeeForm({
    super.key,
    required this.catalog,
    required this.selection,
    required this.feeCodes,
    required this.onSubmit,
    required this.onCancel,
    this.defaultDueAt,
    this.initial,
  });

  @override
  State<FeeForm> createState() => _FeeFormState();
}

class _FeeFormState extends State<FeeForm> {
  late final TextEditingController _label;
  late final TextEditingController _amount;

  String? _feeCode;
  String _currency = 'USD';
  DateTime? _dueAt;
  FeeScopeInput _scope = const FeeScopeInput.allOpenedLevels();

  /// Le dépliant des types hors des usuels.
  bool _showOtherTypes = false;

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
    _dueAt = initial?.dueAt ?? widget.defaultDueAt;
    _scope = initial?.appliesTo ?? const FeeScopeInput.allOpenedLevels();
    _showOtherTypes =
        initial != null && !FeeCodeOrdering.preferred.contains(initial.feeCode);
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Le choix d'un type remplit le libellé, et le montant **seulement s'il est
  /// vide** : écraser une saisie déjà faite serait perdre le travail de
  /// l'utilisateur au moment où il corrige son étiquette.
  void _pickType(FeeCodeOption option) {
    setState(() {
      _feeCode = option.code;
      if (_label.text.trim().isEmpty) _label.text = option.label;
      final indicative = kIndicativeAmountsInCents[option.code];
      if (_amount.text.trim().isEmpty && indicative != null) {
        _amount.text = FeeAmount.inputFromCents(indicative);
      }
    });
  }

  bool get _isValid {
    final cents = FeeAmount.centsFromInput(_amount.text);
    return _feeCode != null &&
        _label.text.trim().isNotEmpty &&
        _dueAt != null &&
        cents != null &&
        cents > 0 &&
        _scope.isValid;
  }

  void _submit() {
    final cents = FeeAmount.centsFromInput(_amount.text);
    if (!_isValid || cents == null) return;
    widget.onSubmit(
      FeeInput(
        feeCode: _feeCode!,
        label: _label.text.trim(),
        amountInCents: cents,
        currency: _currency,
        dueAt: ProvisioningInstant.endOfDayUtc(_dueAt!),
        appliesTo: _scope,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final common = FeeCodeOrdering.common(widget.feeCodes);
    final others = FeeCodeOrdering.others(widget.feeCodes);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: const Color(0xFFA9772E), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24A9772E),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null
                ? l10n.configurationFeeFormTitle
                : l10n.configurationFeeFormEditTitle,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Les usuels en grille, le reste dans un dépliant. C'est un ORDRE :
          // tout code servi reste atteignable, et un code servi que la liste
          // des usuels ne nomme pas tombe dans « autres », jamais dans l'oubli.
          Text(l10n.configurationFeeType, style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final option in common)
                ChoiceChip(
                  label: Text(option.label),
                  selected: _feeCode == option.code,
                  onSelected: (_) => _pickType(option),
                ),
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showOtherTypes = !_showOtherTypes),
                icon: Icon(
                  _showOtherTypes
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(l10n.configurationFeeTypeOthers(others.length)),
              ),
            ),
            if (_showOtherTypes)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final option in others)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: _feeCode == option.code,
                      onSelected: (_) => _pickType(option),
                    ),
                ],
              ),
          ],

          const SizedBox(height: AppSpacing.lg),
          EteeloTextInput(
            controller: _label,
            label: l10n.configurationFeeLabel,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          ConfigurationFieldGrid(
            wideColumns: 3,
            children: [
              EteeloTextInput(
                controller: _amount,
                label: l10n.configurationFeeAmount,
                required: true,
                keyboardType: EteeloTextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              EteeloSelectInput<String>(
                label: l10n.configurationFeeCurrency,
                value: _currency,
                items: const [
                  EteeloSelectItem<String>(value: 'USD', label: 'USD'),
                  // « FC » à l'écran, `CDF` sur le fil : le code ISO à trois
                  // lettres est ce que le serveur attend.
                  EteeloSelectItem<String>(value: 'CDF', label: 'FC'),
                ],
                onChanged: (value) =>
                    setState(() => _currency = value ?? 'USD'),
              ),
              EteeloDateInput(
                label: l10n.configurationFeeDueAt,
                required: true,
                value: _dueAt,
                onChanged: (value) => setState(() => _dueAt = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FeeScopePicker(
            catalog: widget.catalog,
            selection: widget.selection,
            value: _scope,
            onChanged: (scope) => setState(() => _scope = scope),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(l10n.configurationFeeCancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _isValid ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppDimensions.minTouchTarget),
                ),
                child: Text(
                  widget.initial == null
                      ? l10n.configurationFeeAdd
                      : l10n.configurationFeeUpdate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
