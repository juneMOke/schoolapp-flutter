import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte affichée avant toute recherche de facturation — surcouche du composant
/// DS [SearchInvitationCard] (design unifié avec la Réinscription).
class FacturationSearchInvitationCard extends StatelessWidget {
  const FacturationSearchInvitationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchInvitationCard(
      icon: Icons.receipt_long_outlined,
      title: l10n.facturationSearchInvitationTitle,
      message: l10n.facturationSearchInvitationMessage,
    );
  }
}
