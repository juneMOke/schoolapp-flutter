import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Etat vide de l'appel quand la classe selectionnee ne contient aucun eleve.
///
/// Reutilise l'anatomie partagee [EteeloEmptyResult] (medaillon pointille +
/// titre + message + action). L'issue proposee renvoie vers la Composition des
/// classes pour y ajouter des eleves.
class AttendanceResultsEmptyState extends StatelessWidget {
  /// Ouvre la Composition des classes. `null` => aucune action affichee.
  final VoidCallback? onOpenComposition;

  const AttendanceResultsEmptyState({super.key, this.onOpenComposition});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloEmptyResult(
      medallionIcon: Icons.groups_outlined,
      label: l10n.attendanceEmptyStudentsTitle,
      description: l10n.attendanceEmptyStudentsDescription,
      primaryAction: onOpenComposition == null
          ? null
          : FilledButton.icon(
              onPressed: onOpenComposition,
              icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
              label: Text(l10n.attendanceEmptyOpenComposition),
            ),
      autofocusPrimaryAction: onOpenComposition != null,
      fullWidthCard: true,
    );
  }
}
