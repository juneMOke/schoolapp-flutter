import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte d'invitation à lancer une recherche de pré-inscription — surcouche du
/// composant DS [SearchInvitationCard], en miroir de
/// `ReRegistrationEmptyBeforeSearch`.
class PreRegistrationEmptyBeforeSearch extends StatelessWidget {
  const PreRegistrationEmptyBeforeSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchInvitationCard(
      icon: Icons.manage_search_rounded,
      title: l10n.preRegistrationSearchInvitationTitle,
      message: l10n.preRegistrationSearchInvitationMessage,
    );
  }
}
