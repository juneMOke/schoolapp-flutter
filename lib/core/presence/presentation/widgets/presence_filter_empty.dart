import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Des filtres trop étroits : « Aucun … dans ce filtre », ou « Tout le monde
/// est pointé » quand on regardait les « À pointer » — et « Tout afficher ».
class PresenceFilterEmpty extends StatelessWidget {
  final String label;

  /// On regardait « À pointer » et il n'en reste aucun.
  final bool allMarked;
  final VoidCallback onShowAll;

  const PresenceFilterEmpty({
    super.key,
    required this.label,
    required this.allMarked,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: allMarked ? l10n.presenceMarkAllMarked : label,
      medallionIcon: allMarked ? Icons.task_alt : Icons.search_rounded,
      fullWidthCard: true,
      primaryAction: EteeloButton.primary(
        label: l10n.presenceMarkShowAll,
        icon: Icons.restart_alt,
        onPressed: onShowAll,
        fullWidth: false,
      ),
    );
  }
}
