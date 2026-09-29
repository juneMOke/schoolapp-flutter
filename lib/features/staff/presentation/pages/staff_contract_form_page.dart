import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_synced_text_input.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_fields.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_kind_picker.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la page de contrat rend à son appelant.
sealed class StaffContractFormResult {
  const StaffContractFormResult();
}

/// Poser (ou, en correction, remplacer par) cette période.
class StaffContractSubmitted extends StaffContractFormResult {
  final StaffContractDraft draft;

  const StaffContractSubmitted(this.draft);
}

/// Correction sans remplaçant : la période était une saisie en double.
class StaffContractCancelledOnly extends StaffContractFormResult {
  final String reason;

  const StaffContractCancelledOnly(this.reason);
}

/// Poser un contrat (« Nouveau contrat à compter du… ») ou corriger une
/// période. Une page et non une modale : c'est une saisie à plusieurs champs,
/// que le clavier ne doit jamais recouvrir.
class StaffContractFormPage extends StatefulWidget {
  final StaffContractDraft initial;

  /// Correction : un motif est demandé, et « annuler seulement » s'offre.
  final bool correcting;

  const StaffContractFormPage({
    super.key,
    required this.initial,
    this.correcting = false,
  });

  static Future<StaffContractFormResult?> open(
    BuildContext context, {
    required StaffContractDraft initial,
    bool correcting = false,
  }) => Navigator.of(context).push<StaffContractFormResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          StaffContractFormPage(initial: initial, correcting: correcting),
    ),
  );

  @override
  State<StaffContractFormPage> createState() => _StaffContractFormPageState();
}

class _StaffContractFormPageState extends State<StaffContractFormPage> {
  late StaffContractDraft _draft = widget.initial;
  bool _tried = false;

  void _change(StaffContractDraft Function(StaffContractDraft) update) =>
      setState(() => _draft = update(_draft));

  void _submit() {
    final errors = StaffContractValidator.validate(
      _draft,
      correcting: widget.correcting,
    );
    if (errors.isNotEmpty) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(StaffContractSubmitted(_draft));
  }

  /// Sans remplaçant, seul le motif est jugé : les champs de la période
  /// n'ont plus d'objet.
  ///
  /// Le geste ne se défait pas depuis la tablette : il se confirme.
  Future<void> _cancelOnly() async {
    final errors = StaffContractValidator.reasonErrors(
      _draft,
      correcting: true,
    );
    if (errors.isNotEmpty) {
      setState(() => _tried = true);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.staffContractCancelConfirmTitle,
      message: l10n.staffContractCancelConfirmMessage,
      confirmLabel: l10n.staffContractCancelOnly,
      cancelLabel: l10n.staffContractCancelConfirmKeep,
      isDestructive: true,
    );
    if (!mounted || !confirmed) return;
    Navigator.of(context).pop(StaffContractCancelledOnly(_draft.reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errors = _tried
        ? StaffContractMessages.of(
            l10n,
            StaffContractValidator.validate(
              _draft,
              correcting: widget.correcting,
            ),
          )
        : const <StaffContractField, String>{};
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          widget.correcting
              ? l10n.staffContractCorrectTitle
              : l10n.staffContractAddTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.staffAgentBodyMaxWidth,
            ),
            child: StaffFormBlock(
              title: l10n.staffBlockContract,
              subtitle: l10n.staffBlockContractHint,
              icon: Icons.handshake_outlined,
              color: StaffStepStyle.of(2).color,
              children: [
                StaffContractKindPicker(
                  selected: _draft.kind,
                  // Re-toucher le statut choisi ne doit pas effacer le mode de
                  // paiement déjà saisi.
                  onChanged: (kind) {
                    if (kind == _draft.kind) return;
                    _change(
                      (d) => d.copyWith(kind: () => kind, payMode: () => null),
                    );
                  },
                ),
                if (errors[StaffContractField.kind] case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      error,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                StaffContractFields(
                  draft: _draft,
                  errors: errors,
                  onChanged: _change,
                ),
                if (widget.correcting)
                  StaffSyncedTextInput(
                    value: _draft.reason,
                    label: l10n.staffFieldCorrectionReason,
                    required: true,
                    errorText: errors[StaffContractField.reason],
                    keyboardType: EteeloTextInputType.multiline,
                    onChanged: (v) => _change((d) => d.copyWith(reason: v)),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // Un `Wrap` et non une rangée : à 360 dp, les deux libellés de la
          // correction ne tiennent pas côte à côte.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              if (widget.correcting)
                EteeloButton.secondary(
                  label: l10n.staffContractCancelOnly,
                  onPressed: () => unawaited(_cancelOnly()),
                  fullWidth: false,
                ),
              EteeloButton.primary(
                label: widget.correcting
                    ? l10n.staffContractCorrectSubmit
                    : l10n.staffContractAddSubmit,
                icon: Icons.check,
                onPressed: _submit,
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
