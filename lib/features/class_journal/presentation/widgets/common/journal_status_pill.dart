import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La pastille de statut d'une séance (Renseignée, À préparer, Non
/// renseignée, À corriger).
class JournalStatusPill extends StatelessWidget {
  final JournalStatus status;

  const JournalStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final visual = journalStatusVisual(status, AppLocalizations.of(context)!);
    return StatusBadge(
      icon: visual.icon,
      label: visual.label,
      color: visual.color,
      size: StatusBadgeSize.small,
    );
  }
}
