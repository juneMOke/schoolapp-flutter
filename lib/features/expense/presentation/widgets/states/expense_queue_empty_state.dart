import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le vide de la file — **une bonne nouvelle**, et c'est tout l'enjeu.
///
/// Il prend l'anatomie du vide (médaillon, une phrase, une issue), jamais
/// celle de l'échec de la règle n°10 : rien n'a raté, il n'y a simplement plus
/// rien à trancher. Pas d'icône d'alerte, pas de « Réessayer » — l'issue
/// proposée mène au registre, là où la suite du travail se trouve.
class ExpenseQueueEmptyState extends StatelessWidget {
  /// Combien de demandes accordées restent à payer : la file est vide, mais
  /// l'école doit encore de l'argent, et le dire ici évite de croire que tout
  /// est réglé.
  final int approvedToPay;

  final VoidCallback onOpenRegister;

  const ExpenseQueueEmptyState({
    super.key,
    required this.approvedToPay,
    required this.onOpenRegister,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.expenseQueueEmptyTitle,
      description: approvedToPay == 0
          ? l10n.expenseQueueEmptyMessage
          : l10n.expenseQueueEmptyWithApproved(approvedToPay),
      medallionIcon: Icons.task_alt,
      fullWidthCard: true,
      primaryAction: EteeloButton.secondary(
        label: l10n.expenseQueueOpenRegister,
        icon: Icons.receipt_long_outlined,
        onPressed: onOpenRegister,
        fullWidth: false,
      ),
    );
  }
}
