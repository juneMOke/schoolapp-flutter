import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pied du formulaire : renoncer, enregistrer. [onSubmit] à `null` quand
/// l'école n'a aucun type de dépense — il n'y a rien à enregistrer.
class ExpenseFormFooter extends StatelessWidget {
  final bool isEdit;
  final VoidCallback? onSubmit;

  /// Le libellé d'envoi quand ce n'est ni créer ni modifier (« Déclarer »).
  final String? submitLabel;

  const ExpenseFormFooter({
    super.key,
    required this.isEdit,
    required this.onSubmit,
    this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: [
          EteeloButton.ghost(
            label: l10n.expenseFormCancel,
            onPressed: () => Navigator.of(context).pop(),
            fullWidth: false,
          ),
          EteeloButton.primary(
            label:
                submitLabel ??
                (isEdit
                    ? l10n.expenseFormSaveEdit
                    : l10n.expenseFormSaveCreate),
            icon: Icons.check,
            onPressed: onSubmit,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
