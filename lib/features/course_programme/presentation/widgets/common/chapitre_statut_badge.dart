import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_statut_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Badge du statut d'un chapitre (icône + libellé).
class ChapitreStatutBadge extends StatelessWidget {
  final ChapitreStatut statut;
  final StatusBadgeSize size;

  const ChapitreStatutBadge({
    super.key,
    required this.statut,
    this.size = StatusBadgeSize.small,
  });

  @override
  Widget build(BuildContext context) {
    final visual = ChapitreStatutVisual.of(statut);
    return StatusBadge(
      icon: visual.icon,
      label: ChapitreStatutVisual.label(AppLocalizations.of(context)!, statut),
      color: visual.accent,
      size: size,
    );
  }
}
