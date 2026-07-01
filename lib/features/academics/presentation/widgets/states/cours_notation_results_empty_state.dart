import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État vide de la page détail (spec §11) : le cours n'a aucune évaluation.
/// Réutilise l'anatomie partagée [EteeloEmptyResult]. Sans action (la création
/// d'évaluation n'est pas câblée).
class CoursNotationResultsEmptyState extends StatelessWidget {
  const CoursNotationResultsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.courseDetailEmptyTitle,
      description: l10n.courseDetailEmptyDescription,
      medallionIcon: Icons.assignment_outlined,
      fullWidthCard: true,
    );
  }
}
