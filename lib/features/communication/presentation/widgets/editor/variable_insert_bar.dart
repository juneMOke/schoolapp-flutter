import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Insérer : + Nom de l'élève + Classe + Montant dû ». Le montant n'est
/// offert qu'en mode Retards de paiement.
class VariableInsertBar extends StatelessWidget {
  final bool amountAllowed;
  final ValueChanged<AnnouncementVariable>? onInsert;

  const VariableInsertBar({
    super.key,
    required this.amountAllowed,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insert = onInsert;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.communicationInsert,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        for (final variable in AnnouncementVariable.values)
          EteeloButton.ghost(
            label: l10n.variableLabel(variable),
            icon: Icons.add,
            size: EteeloButtonSize.compact,
            fullWidth: false,
            tooltip: variable == AnnouncementVariable.amount && !amountAllowed
                ? l10n.communicationAmountOnlyOverdue
                : null,
            onPressed:
                insert == null ||
                    (variable == AnnouncementVariable.amount && !amountAllowed)
                ? null
                : () => insert(variable),
          ),
      ],
    );
  }
}
