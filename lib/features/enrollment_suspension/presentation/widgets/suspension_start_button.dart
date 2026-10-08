import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Garde commune des gestes de désactivation : absent sans
/// `enrollment.suspend` (le geste mourrait en 403 dans l'outbox), et gelé
/// avec la session en lecture seule.
class SuspensionGate extends StatelessWidget {
  final Widget child;

  const SuspensionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) => PermissionGate.access(
    kEnrollmentSuspendAccess,
    child: SessionWriteGate(child: child),
  );
}

/// « Désactiver des élèves », dans la barre de résultats : ouvre le mode
/// sélection.
class SuspensionStartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SuspensionStartButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => SuspensionGate(
    child: EteeloButton.secondary(
      label: AppLocalizations.of(context)!.suspensionStartSelection,
      icon: Icons.person_remove_outlined,
      fullWidth: false,
      onPressed: onPressed,
    ),
  );
}
