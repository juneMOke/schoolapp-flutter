import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Ce qu'un état du circuit montre : une encre, le fond qu'elle habille, sa
/// bordure et une icône.
///
/// Les teintes viennent des jetons du socle, jamais des hexadécimaux de la
/// spec : l'attente et le refus empruntent la famille des frais (même ambre,
/// même rouge), l'approbation le bleu de marque, le retrait l'encre muette.
///
/// Champs **nommés** : un enregistrement positionnel de quatre couleurs se
/// lirait de travers au premier changement d'ordre, sans que rien ne le dise.
typedef ExpenseStatusVisuals = ({
  Color color,
  Color soft,
  Color border,
  IconData icon,
});

/// Partagé par la pastille et par la chaîne de validation : deux lectures du
/// même état, et **une** table de teintes. En laisser une copie à chacune,
/// c'est se garantir qu'un jour l'une dira rouge là où l'autre dit ambre.
ExpenseStatusVisuals expenseStatusVisuals(ExpenseStatus status) =>
    switch (status) {
      ExpenseStatus.pending => (
        color: AppColors.feeStatusPartial,
        soft: AppColors.feeStatusPartialSoft,
        border: AppColors.feeStatusPartialBorder,
        icon: Icons.schedule,
      ),
      ExpenseStatus.approved => (
        color: AppColors.bleuArdoise,
        soft: AppColors.bleuArdoiseSoft,
        border: AppColors.border,
        icon: Icons.verified_outlined,
      ),
      ExpenseStatus.paid => (
        color: AppColors.feeStatusPaid,
        soft: AppColors.feeStatusPaidSoft,
        border: AppColors.feeStatusPaidBorder,
        icon: Icons.check_circle_outline,
      ),
      ExpenseStatus.refused => (
        color: AppColors.feeStatusDue,
        soft: AppColors.feeStatusDueSoft,
        border: AppColors.feeStatusDueBorder,
        icon: Icons.cancel_outlined,
      ),
      ExpenseStatus.retracted => (
        color: AppColors.textMuted,
        soft: AppColors.surfaceAlt,
        border: AppColors.border,
        icon: Icons.undo,
      ),
    };
