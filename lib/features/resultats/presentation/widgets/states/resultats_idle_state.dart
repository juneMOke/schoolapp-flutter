import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Invite initiale (spec machine à états : `idle`) : aucune recherche lancée.
/// Réutilise l'anatomie [EteeloEmptyResult] (médaillon pointillé) sans action.
class ResultatsIdleState extends StatelessWidget {
  const ResultatsIdleState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      medallionIcon: Icons.insights_outlined,
      label: l10n.resultatsIdleTitle,
      description: l10n.resultatsIdleDescription,
      fullWidthCard: true,
    );
  }
}
