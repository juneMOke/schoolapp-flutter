import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rien dans la vue choisie.
class JustificationEmptyState extends StatelessWidget {
  final JustificationQueueFilter filter;

  const JustificationEmptyState({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = filter == JustificationQueueFilter.open;
    return EteeloEmptyResult(
      label: open
          ? l10n.justificationEmptyOpenTitle
          : l10n.justificationEmptyDecidedTitle,
      description: l10n.justificationEmptyDescription,
      medallionIcon: open ? Icons.mark_email_read_outlined : Icons.inbox,
      fullWidthCard: true,
    );
  }
}
