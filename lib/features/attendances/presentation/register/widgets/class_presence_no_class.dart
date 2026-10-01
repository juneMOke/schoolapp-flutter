import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Avant le choix d'une classe : l'invitation à la choisir, ou l'absence de
/// classe sur la tablette (elles arrivent avec la synchronisation).
class ClassPresenceNoClass extends StatelessWidget {
  final bool hasClasses;
  final VoidCallback onPick;

  const ClassPresenceNoClass({
    super.key,
    required this.hasClasses,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!hasClasses) {
      return EteeloEmptyResult(
        label: l10n.classPresenceNoClassesTitle,
        description: l10n.classPresenceNoClassesMessage,
        medallionIcon: Icons.cloud_sync_outlined,
        fullWidthCard: true,
      );
    }
    return EteeloEmptyResult(
      label: l10n.classPresenceNoClassTitle,
      description: l10n.classPresenceNoClassMessage,
      medallionIcon: Icons.groups_outlined,
      fullWidthCard: true,
      primaryAction: EteeloButton.primary(
        label: l10n.classPresencePickClass,
        icon: Icons.class_outlined,
        onPressed: onPick,
        fullWidth: false,
      ),
      autofocusPrimaryAction: true,
    );
  }
}
