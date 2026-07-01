import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État vide de la liste « Mes cours » : aucun cours rattaché à l'enseignant.
/// Pas d'action (l'affectation des cours se fait hors de cet écran).
class MyCoursesResultsEmptyState extends StatelessWidget {
  const MyCoursesResultsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloEmptyResult(
      label: l10n.myCoursesEmptyTitle,
      description: l10n.myCoursesEmptyDescription,
      medallionIcon: Icons.menu_book_outlined,
      fullWidthCard: true,
    );
  }
}
