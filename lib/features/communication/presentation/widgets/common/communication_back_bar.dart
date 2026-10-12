import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « ← Communiqués » : retour à la liste, filtres intacts.
class CommunicationBackBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String? label;

  const CommunicationBackBar({super.key, required this.onBack, this.label});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: EteeloButton.ghost(
      label: label ?? AppLocalizations.of(context)!.communicationBackToList,
      icon: Icons.arrow_back,
      onPressed: onBack,
      fullWidth: false,
    ),
  );
}
