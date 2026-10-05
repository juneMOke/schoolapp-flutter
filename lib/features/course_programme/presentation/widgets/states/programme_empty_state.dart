import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Programme vide » : l'issue est de créer un chapitre — pour qui peut
/// écrire le programme ; la direction lit seulement le constat.
class ProgrammeEmptyState extends StatelessWidget {
  final VoidCallback? onCreate;

  const ProgrammeEmptyState({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final create = onCreate;
    final canWrite = create != null && ProgrammeWriteGate.allows(context);
    return EteeloEmptyResult(
      label: l10n.programmeEmptyTitle,
      description: canWrite
          ? l10n.programmeEmptyMessage
          : l10n.programmeEmptyReadOnlyMessage,
      medallionIcon: Icons.layers_outlined,
      fullWidthCard: true,
      primaryAction: canWrite
          ? ProgrammeWriteGate(
              child: EteeloButton.primary(
                label: l10n.programmeEmptyAction,
                icon: Icons.add_rounded,
                onPressed: create,
                fullWidth: false,
              ),
            )
          : null,
    );
  }
}
