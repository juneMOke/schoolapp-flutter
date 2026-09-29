import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ressources humaines ▸ Fichier du personnel.
///
/// **Page d'attente.** Le menu est câblé avant l'écran : la liste des agents
/// (grille / liste, synthèse, filtres) lit un référentiel local que la
/// synchronisation remplira une fois le contrat d'API du back publié (lot H0).
/// D'ici là, la page dit honnêtement qu'il n'y a rien à montrer, avec l'état
/// vide partagé (règle #10) plutôt qu'un écran ad hoc.
///
/// Le sous-menu est gardé par `hr.staff.read`, qu'aucun rôle ne détient tant
/// que le serveur ne l'a pas semé : en pratique, personne n'atteint cette page
/// avant que la vraie liste ne la remplace.
class StaffFilePage extends StatelessWidget {
  const StaffFilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        child: EteeloEmptyResult(
          label: l10n.staffFileUnavailableTitle,
          description: l10n.staffFileUnavailableDescription,
          medallionIcon: Icons.badge_outlined,
        ),
      ),
    );
  }
}
