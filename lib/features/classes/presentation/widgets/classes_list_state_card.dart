import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';

/// Carte affichée **avant toute recherche** dans la liste des classes —
/// surcouche du composant DS [SearchInvitationCard], comme la Facturation
/// (`FacturationSearchInvitationCard`) et le Contrôle des frais
/// (`FeeControlSearchInvitationCard`).
///
/// Elle réimplémentait jusqu'ici le même médaillon, le même titre et le même
/// message à la main — soixante-sept lignes pour les trois mêmes entrées — en
/// empruntant au passage des jetons `finance` (`financeDetailAccent`,
/// `financeDetailShadow`) à l'intérieur d'un widget `classes`.
///
/// ⚠️ Son nom reste trompeur : ce n'est pas une carte d'**état** de résultats.
/// Chargement, vide et erreur sont délégués au socle par `isLoading`,
/// `isError`, `emptyLabel` et `errorLabel` ; cette carte-ci ne sert qu'au cas
/// `request == null`, c'est-à-dire « vous n'avez pas encore cherché ». La
/// signature et le nom sont conservés pour que l'unique appelant ne bouge pas.
class ClassesListStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ClassesListStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) =>
      SearchInvitationCard(icon: icon, title: title, message: message);
}
