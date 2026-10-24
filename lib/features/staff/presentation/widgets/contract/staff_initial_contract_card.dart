import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_editor.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le contrat d'un agent **en création**, saisi à même l'étape « Poste &
/// contrat » — le formulaire de « Nouveau contrat », sans page à ouvrir.
///
/// Facultatif : sans statut choisi, l'agent est enregistré « contrat à
/// poser ». Le contrat n'est pas un champ de la fiche : il se pose juste
/// après elle, comme un geste à part, sous `hr.pay.write`.
class StaffInitialContractCard extends StatelessWidget {
  final StaffContractDraft? contract;

  /// Les refus à montrer — vides tant que l'étape n'est pas tentée.
  final Map<StaffContractField, StaffContractError> errors;
  final ValueChanged<StaffContractDraft Function(StaffContractDraft)> onChanged;

  /// « Enregistrer sans contrat » : oublie la saisie entamée.
  final VoidCallback onClear;

  const StaffInitialContractCard({
    super.key,
    required this.contract,
    required this.errors,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canWrite = PermissionGate.allows(context, const [Perm.hrPayWrite]);
    final contract = this.contract ?? const StaffContractDraft();
    return StaffFormBlock(
      title: l10n.staffBlockContract,
      subtitle: canWrite
          ? l10n.staffInitialContractHint
          : l10n.staffInitialContractNoRight,
      icon: Icons.handshake_outlined,
      color: StaffStepStyle.of(2).color,
      children: [
        if (canWrite) ...[
          StaffContractEditor(
            draft: contract,
            errors: StaffContractMessages.of(l10n, errors),
            onChanged: onChanged,
          ),
          if (contract.kind != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: EteeloButton.ghost(
                label: l10n.staffInitialContractSkip,
                icon: Icons.close,
                onPressed: onClear,
                fullWidth: false,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
