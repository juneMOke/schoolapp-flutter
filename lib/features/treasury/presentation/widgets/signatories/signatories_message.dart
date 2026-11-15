import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un message de la modale des signataires (liste changée, échec, mise en
/// garde), annoncé par le lecteur d'écran dès qu'il paraît.
class SignatoriesMessage extends StatelessWidget {
  final String text;
  final Color color;

  const SignatoriesMessage({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(text, style: AppTypography.bodySmall.copyWith(color: color)),
  );
}

/// « Revenir aux blocs par défaut » efface la liste désignée : on demande
/// d'abord.
Future<bool> confirmRestoreDefaults(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppConfirmationDialog(
    context: context,
    title: l10n.treasurySignatoriesUseDefaults,
    message: l10n.treasurySignatoriesDefaultsConfirm,
    confirmLabel: l10n.treasurySignatoriesUseDefaults,
    cancelLabel: l10n.treasuryCancel,
    isDestructive: true,
  );
}
