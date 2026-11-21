import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
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

/// L'aide et les gestes d'un calendrier. L'aide suit le geste réel : au
/// doigt « Touchez », à la souris « Cliquez » ; en [compact], toucher un jour
/// le sélectionne (I7). Avec [menu], Imprimer, Document du ministère et
/// Dupliquer passent dans un menu « ⋯ », et l'aide, « Ajouter » et
/// « Publier » tiennent sur une ligne ; « Ajouter » devient le bouton
/// flottant de la page sous [addAsFab].
class CalendarActionsRow extends StatelessWidget {
  final CalendarPhase phase;
  final bool canWrite;
  final CalendarActions actions;
  final bool compact;
  final bool menu;

  const CalendarActionsRow({
    super.key,
    required this.phase,
    required this.canWrite,
    required this.actions,
    this.compact = false,
    this.menu = false,
  });

  /// Fenêtre de téléphone : « Ajouter » est le bouton flottant de la page.
  static bool addAsFab(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.fabExtendedMinWidth;

  String _help(AppLocalizations l10n) {
    if (phase.isReadOnly) return l10n.schoolCalendarHelpArchived;
    final pointer = expectsPhysicalKeyboard;
    if (!canWrite) {
      return pointer
          ? l10n.schoolCalendarHelpRead
          : l10n.schoolCalendarHelpReadTouch;
    }
    if (compact) return l10n.schoolCalendarHelpTouch;
    return pointer
        ? l10n.schoolCalendarHelpDesktop
        : l10n.schoolCalendarHelpTouchWide;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final help = Text(_help(l10n), style: AppTypography.bodySmall);
    final publish = phase == CalendarPhase.draft ? actions.publish : null;
    final add = canWrite && !addAsFab(context)
        ? () => actions.addOn(null)
        : null;
    final secondary = <_Secondary>[
      if (actions.print case final print?)
        _Secondary(l10n.schoolCalendarPrint, Icons.print_outlined, print),
      if (actions.officialDocument case final document?)
        _Secondary(
          l10n.schoolCalendarOfficialDocument,
          Icons.description_outlined,
          document,
        ),
      if (actions.duplicate case final duplicate?)
        _Secondary(
          l10n.schoolCalendarDuplicate,
          Icons.copy_all_outlined,
          duplicate,
        ),
    ];
    final addButton = add == null
        ? null
        : SecondaryButton(
            label: l10n.schoolCalendarAdd,
            icon: Icons.add_rounded,
            fullWidth: false,
            onPressed: add,
          );
    final publishButton = publish == null
        ? null
        : PrimaryButton(
            label: l10n.schoolCalendarPublish,
            icon: Icons.publish_outlined,
            fullWidth: false,
            onPressed: publish,
          );
    if (compact || menu) {
      return Row(
        children: [
          Expanded(child: help),
          for (final button in [?addButton, ?publishButton]) ...[
            const SizedBox(width: AppSpacing.sm),
            button,
          ],
          if (secondary.isNotEmpty) _MoreMenu(items: secondary),
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        help,
        for (final item in secondary)
          SecondaryButton(
            label: item.label,
            icon: item.icon,
            fullWidth: false,
            onPressed: item.onPressed,
          ),
        ?addButton,
        ?publishButton,
      ],
    );
  }
}

class _Secondary {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _Secondary(this.label, this.icon, this.onPressed);
}

class _MoreMenu extends StatelessWidget {
  final List<_Secondary> items;

  const _MoreMenu({required this.items});

  @override
  Widget build(BuildContext context) => PopupMenuButton<_Secondary>(
    tooltip: AppLocalizations.of(context)!.schoolCalendarMoreActions,
    icon: const Icon(Icons.more_horiz),
    onSelected: (item) => item.onPressed(),
    itemBuilder: (_) => [
      for (final item in items)
        PopupMenuItem(
          value: item,
          child: Row(
            children: [
              Icon(item.icon),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: Text(item.label)),
            ],
          ),
        ),
    ],
  );
}
