import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte affichée avant tout contrôle — surcouche du composant DS
/// [SearchInvitationCard], comme la Facturation.
class FeeControlSearchInvitationCard extends StatelessWidget {
  const FeeControlSearchInvitationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchInvitationCard(
      icon: Icons.fact_check_outlined,
      title: l10n.feeControlInvitationTitle,
      message: l10n.feeControlInvitationMessage,
    );
  }
}
