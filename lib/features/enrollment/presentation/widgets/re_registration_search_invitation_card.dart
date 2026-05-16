import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ReRegistrationSearchInvitationCard extends StatelessWidget {
  const ReRegistrationSearchInvitationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchFormCard(
      showShadow: false,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.manage_search_rounded,
            size: 44,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.reRegistrationSearchInvitationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.reRegistrationSearchInvitationMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
