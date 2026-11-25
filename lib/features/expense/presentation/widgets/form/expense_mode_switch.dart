import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/search/search_hint_pill.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En tête du bon de sortie : **déclarer** une dépense déjà payée, ou la
/// **demander** pour autorisation (v3). Montré seulement avec
/// `expense.declare` (F35).
///
/// Même anatomie que la bascule des recherches : annoncée, sur toute la
/// largeur, et l'aide du mode actif nomme l'autre — c'est la porte de sortie
/// de qui est entré par la mauvaise.
class ExpenseModeSwitch extends StatelessWidget {
  final ExpenseMode mode;
  final ValueChanged<ExpenseMode> onChanged;

  const ExpenseModeSwitch({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final declaring = mode == ExpenseMode.declaration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseModeLabel.toUpperCase(),
          style: AppTextStyles.badge.copyWith(
            color: AppColors.terreCuite,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        SegmentedTabFilter<ExpenseMode>(
          selected: mode,
          onSelected: onChanged,
          semanticsLabel: l10n.expenseModeSemantics,
          expand: true,
          options: [
            SegmentedTabOption(
              label: l10n.expenseModeDeclaration,
              value: ExpenseMode.declaration,
              icon: Icons.receipt_long_outlined,
            ),
            SegmentedTabOption(
              label: l10n.expenseModeAuthorization,
              value: ExpenseMode.authorization,
              icon: Icons.approval_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SearchHintPill(
          icon: declaring
              ? Icons.receipt_long_outlined
              : Icons.approval_outlined,
          text: declaring
              ? l10n.expenseModeDeclarationHint
              : l10n.expenseModeAuthorizationHint,
        ),
      ],
    );
  }
}
