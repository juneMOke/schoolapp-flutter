import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes que la vue d'un calendrier déclenche ; la page les branche sur
/// les sur-couches (O1-O7).
class CalendarActions {
  final ValueChanged<CalendarElement> openElement;
  final ValueChanged<DateTime?> addOn;
  final VoidCallback? publish;
  final VoidCallback? duplicate;
  final VoidCallback? print;

  /// Le document officiel du ministère, joint au cadre (en ligne).
  final VoidCallback? officialDocument;
  final VoidCallback back;

  const CalendarActions({
    required this.openElement,
    required this.addOn,
    required this.back,
    this.publish,
    this.duplicate,
    this.print,
    this.officialDocument,
  });
}

class CalendarActionsRow extends StatelessWidget {
  final CalendarPhase phase;
  final bool canWrite;
  final CalendarActions actions;

  const CalendarActionsRow({
    super.key,
    required this.phase,
    required this.canWrite,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final help = phase.isReadOnly
        ? l10n.schoolCalendarHelpArchived
        : canWrite
        ? l10n.schoolCalendarHelpDesktop
        : l10n.schoolCalendarHelpRead;
    final print = actions.print;
    final duplicate = actions.duplicate;
    final publish = actions.publish;
    final document = actions.officialDocument;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(help, style: AppTypography.bodySmall),
        if (print != null)
          SecondaryButton(
            label: l10n.schoolCalendarPrint,
            icon: Icons.print_outlined,
            fullWidth: false,
            onPressed: print,
          ),
        if (document != null)
          SecondaryButton(
            label: l10n.schoolCalendarOfficialDocument,
            icon: Icons.description_outlined,
            fullWidth: false,
            onPressed: document,
          ),
        if (duplicate != null)
          SecondaryButton(
            label: l10n.schoolCalendarDuplicate,
            icon: Icons.copy_all_outlined,
            fullWidth: false,
            onPressed: duplicate,
          ),
        if (canWrite)
          SecondaryButton(
            label: l10n.schoolCalendarAdd,
            icon: Icons.add_rounded,
            fullWidth: false,
            onPressed: () => actions.addOn(null),
          ),
        if (phase == CalendarPhase.draft && publish != null)
          PrimaryButton(
            label: l10n.schoolCalendarPublish,
            icon: Icons.publish_outlined,
            fullWidth: false,
            onPressed: publish,
          ),
      ],
    );
  }
}
