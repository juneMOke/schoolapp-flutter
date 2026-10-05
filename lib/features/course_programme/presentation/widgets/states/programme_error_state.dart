import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur de lecture du programme. Il se lit sur la tablette : la seule panne
/// possible est celle de la base locale — l'anatomie « serveur » de la charte,
/// avec « Réessayer ».
class ProgrammeResultsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const ProgrammeResultsErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloErrorResult(
      type: EteeloErrorType.server,
      title: l10n.programmeErrorTitle,
      message: l10n.programmeErrorMessage,
      fullWidthCard: true,
      primaryAction: EteeloButton.primary(
        label: l10n.myCoursesErrorRetry,
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
        fullWidth: false,
      ),
    );
  }
}
