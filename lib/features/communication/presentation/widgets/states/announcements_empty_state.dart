import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Aucune ligne à montrer : aucun communiqué cette année, ou aucun qui
/// réponde aux filtres.
class AnnouncementsEmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onClearFilters;
  final VoidCallback? onCreate;
  final VoidCallback? onUseTemplate;

  const AnnouncementsEmptyState({
    super.key,
    required this.filtered,
    required this.onClearFilters,
    this.onCreate,
    this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (filtered) {
      return EteeloEmptyResult(
        label: l10n.communicationEmptyFilteredTitle,
        description: l10n.communicationEmptyFilteredMessage,
        medallionIcon: Icons.search,
        fullWidthCard: true,
        primaryAction: EteeloButton.secondary(
          label: l10n.communicationFilterClearAll,
          icon: Icons.close,
          onPressed: onClearFilters,
          fullWidth: false,
        ),
      );
    }
    final create = onCreate;
    final useTemplate = onUseTemplate;
    return EteeloEmptyResult(
      label: l10n.communicationEmptyTitle,
      description: l10n.communicationEmptyMessage,
      medallionIcon: Icons.campaign_outlined,
      fullWidthCard: true,
      primaryAction: create == null
          ? null
          : EteeloButton.primary(
              label: l10n.communicationNew,
              icon: Icons.add,
              onPressed: create,
              fullWidth: false,
            ),
      secondaryAction: useTemplate == null
          ? null
          : EteeloButton.secondary(
              label: l10n.communicationFromTemplate,
              icon: Icons.dashboard_customize_outlined,
              onPressed: useTemplate,
              fullWidth: false,
            ),
    );
  }
}
