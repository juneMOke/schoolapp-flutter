import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte d'invitation à lancer une recherche de réinscription — surcouche du
/// composant DS [SearchInvitationCard].
class ReRegistrationEmptyBeforeSearch extends StatelessWidget {
  const ReRegistrationEmptyBeforeSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchInvitationCard(
      icon: Icons.manage_search_rounded,
      title: l10n.reRegistrationSearchInvitationTitle,
      message: l10n.reRegistrationSearchInvitationMessage,
    );
  }
}
