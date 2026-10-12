import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/helpers/support_contact.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'action qui suit un échec, selon sa famille — la même partout dans le
/// module : 403 → contacter l'administrateur (jamais « Réessayer »), 401 → se
/// reconnecter, sinon « Réessayer » quand [onRetry] est donné.
///
/// [prominent] : bouton plein (zone de résultats) ou discret (bandeau,
/// encart).
Widget? communicationErrorAction(
  BuildContext context,
  EteeloErrorType type, {
  VoidCallback? onRetry,
  bool prominent = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  return switch (type) {
    EteeloErrorType.forbidden => EteeloButton.ghost(
      label: l10n.communicationErrorContactAdmin,
      icon: Icons.mail_outline,
      onPressed: contactSupport,
      fullWidth: false,
    ),
    EteeloErrorType.unauthorized =>
      prominent
          ? EteeloButton.primary(
              label: l10n.communicationErrorReconnect,
              icon: Icons.login,
              onPressed: () => _reconnect(context),
              fullWidth: false,
            )
          : EteeloButton.secondary(
              label: l10n.communicationErrorReconnect,
              icon: Icons.login,
              onPressed: () => _reconnect(context),
              fullWidth: false,
            ),
    _ when onRetry == null => null,
    _ =>
      prominent
          ? EteeloButton.primary(
              label: l10n.communicationRetry,
              icon: Icons.refresh,
              onPressed: onRetry,
              fullWidth: false,
            )
          : EteeloButton.ghost(
              label: l10n.communicationRetry,
              icon: Icons.refresh,
              onPressed: onRetry,
              fullWidth: false,
            ),
  };
}

void _reconnect(BuildContext context) =>
    context.read<AuthBloc>().add(const AuthLogoutRequested());
