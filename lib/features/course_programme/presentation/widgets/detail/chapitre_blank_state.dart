import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Chapitre non renseigné » : ni objectif, ni note, ni ressource. L'issue —
/// compléter le chapitre dans sa modale — n'existe que pour qui l'écrit.
class ChapitreBlankState extends StatelessWidget {
  final VoidCallback? onComplete;

  const ChapitreBlankState({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final complete = onComplete;
    return EteeloEmptyResult(
      label: l10n.chapitreBlankTitle,
      description: l10n.chapitreBlankMessage,
      medallionIcon: Icons.edit_note_rounded,
      fullWidthCard: true,
      minHeight: 0,
      primaryAction: complete == null
          ? null
          : ProgrammeWriteGate(
              child: EteeloButton.primary(
                label: l10n.chapitreBlankAction,
                icon: Icons.edit_outlined,
                onPressed: complete,
                fullWidth: false,
              ),
            ),
    );
  }
}
