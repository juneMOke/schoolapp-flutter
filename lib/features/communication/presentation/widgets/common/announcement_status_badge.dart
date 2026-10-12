import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le statut d'un communiqué, par le badge du socle.
class AnnouncementStatusBadge extends StatelessWidget {
  final AnnouncementStatus status;

  const AnnouncementStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = statusTone(status);
    return StatusBadge(
      icon: tone.icon,
      label: AppLocalizations.of(context)!.statusLabel(status),
      color: tone.ink,
      size: StatusBadgeSize.small,
    );
  }
}
