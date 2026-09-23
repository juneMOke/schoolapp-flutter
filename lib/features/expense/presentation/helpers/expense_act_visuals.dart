import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Ce qu'un acte du fil montre : une icône et **une** encre, qui sert au
/// pictogramme comme au libellé.
///
/// Les familles sont celles de la pastille de statut — l'approbation reste
/// bleue, le refus rouge, le paiement vert — mais l'ambre y est plus sombre :
/// dans le fil, le mot se pose sur la bulle neutre, où `feeStatusPartial` ne
/// s'écrit qu'à 3,83. C'est la même doctrine qu'ailleurs dans le socle : une
/// teinte fonde un pavé, une autre s'écrit dessus.
typedef ExpenseActVisuals = ({Color ink, IconData icon});

ExpenseActVisuals expenseActVisuals(ExpenseAct? act) => switch (act) {
  // Commentaire libre : il ne constate rien, il ne prend donc aucune couleur
  // de décision — la bulle le donne déjà pour ce qu'il est.
  null => (ink: AppColors.textSecondary, icon: Icons.chat_bubble_outline),
  ExpenseAct.deposit => (ink: AppColors.bleuArdoise, icon: Icons.send_outlined),
  ExpenseAct.reminder => (
    ink: AppColors.feeStatusPartialInk,
    icon: Icons.notifications_active_outlined,
  ),
  ExpenseAct.approval => (
    ink: AppColors.bleuArdoise,
    icon: Icons.verified_outlined,
  ),
  ExpenseAct.refusal => (
    ink: AppColors.feeStatusDue,
    icon: Icons.cancel_outlined,
  ),
  ExpenseAct.payment => (
    ink: AppColors.feeStatusPaid,
    icon: Icons.check_circle_outline,
  ),
  ExpenseAct.retraction => (ink: AppColors.textSecondary, icon: Icons.undo),
  ExpenseAct.reopening => (
    ink: AppColors.feeStatusPartialInk,
    icon: Icons.restart_alt,
  ),
  ExpenseAct.correction => (ink: AppColors.bleuArdoise, icon: Icons.replay),
  ExpenseAct.edit => (ink: AppColors.bleuArdoise, icon: Icons.edit_outlined),
};
