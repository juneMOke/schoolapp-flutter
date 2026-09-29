import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux vides du fichier : aucun agent du tout, ou des filtres trop
/// étroits. Il remplace la zone de résultats seule : synthèse et filtres
/// restent au-dessus, ce sont eux qui expliquent le vide.
class StaffEmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onResetFilters;

  const StaffEmptyState({
    super.key,
    required this.filtered,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (filtered) {
      return EteeloEmptyResult(
        label: l10n.staffEmptySearchTitle,
        description: l10n.staffEmptySearchMessage,
        medallionIcon: Icons.search_rounded,
        fullWidthCard: true,
        primaryAction: EteeloButton.primary(
          label: l10n.staffResetFilters,
          icon: Icons.restart_alt,
          onPressed: onResetFilters,
          fullWidth: false,
        ),
      );
    }
    return EteeloEmptyResult(
      label: l10n.staffEmptyFileTitle,
      description: l10n.staffEmptyFileMessage,
      medallionIcon: Icons.groups_outlined,
      fullWidthCard: true,
    );
  }
}
