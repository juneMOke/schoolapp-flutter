import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_tile.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois compteurs d'une journée — présents, en retard, absents — en
/// tuiles de même largeur. La modale de validation et le bandeau du jour
/// validé montrent les mêmes : on relit ce qu'on vient de confirmer, sous la
/// forme où on l'a confirmé.
class PresenceCountRow extends StatelessWidget {
  final int present;
  final int late;
  final int absent;

  const PresenceCountRow({
    super.key,
    required this.present,
    required this.late,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget tile(PresenceStatus status, int value) => Expanded(
      child: PresenceCountTile(
        tone: status,
        label: PresenceLabels.filter(l10n, status),
        value: '$value',
      ),
    );
    return Row(
      children: [
        tile(PresenceStatus.present, present),
        const SizedBox(width: AppSpacing.sm),
        tile(PresenceStatus.late, late),
        const SizedBox(width: AppSpacing.sm),
        tile(PresenceStatus.absent, absent),
      ],
    );
  }
}
