import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';

/// État vide du tableau de bord.
///
/// Deux vides différents, deux textes — comme partout dans ce module : « aucune
/// créance sur l'appareil » appelle une synchronisation, « personne ne porte ce
/// frais ici » est un constat sur l'école. Les confondre enverrait chercher une
/// panne là où il n'y a qu'un frais inapplicable.
class FeeControlDashboardEmptyState extends StatelessWidget {
  final String title;
  final String description;

  const FeeControlDashboardEmptyState({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return EteeloEmptyResult(
      label: title,
      description: description,
      medallionIcon: Icons.insights_outlined,
      accentColor: AppColors.accueilFeeControlAccent,
    );
  }
}
