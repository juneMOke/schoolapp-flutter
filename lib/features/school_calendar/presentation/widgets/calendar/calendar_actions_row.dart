import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_round_icon_button.dart';
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

/// L'aide et les gestes d'un calendrier (spec §4.6 C, maquette `CalDetail`),
/// dans leur carte, avec sous eux l'avis [notice] (« à vérifier »).
///
/// L'aide suit le geste réel : au doigt « Touchez », à la souris « Cliquez » ;
/// en [compact], toucher un jour le sélectionne (I7). Imprimer en discret,
/// Dupliquer et Document en secondaire, Ajouter en principal — en secondaire
/// à côté de Publier. En [compact] (sous 600) : l'aide au-dessus, puis
/// Imprimer, Document et Dupliquer en icônes de 48 dp, et Ajouter et Publier
/// qui se partagent le reste de la ligne.
class CalendarActionsRow extends StatelessWidget {
  final CalendarPhase phase;
  final bool canWrite;
  final CalendarActions actions;
  final bool compact;
  final Widget? notice;

  const CalendarActionsRow({
    super.key,
    required this.phase,
    required this.canWrite,
    required this.actions,
    this.compact = false,
    this.notice,
  });

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
    final help = Text(
      _help(l10n),
      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
    );
    final publish = phase == CalendarPhase.draft ? actions.publish : null;
    final add = canWrite ? () => actions.addOn(null) : null;
    final size = expectsPhysicalKeyboard
        ? EteeloButtonSize.compact
        : EteeloButtonSize.regular;
    final addButton = add == null
        ? null
        : publish == null
        ? EteeloButton.primary(
            label: l10n.schoolCalendarAdd,
            icon: Icons.add_rounded,
            size: size,
            fullWidth: compact,
            onPressed: add,
          )
        : EteeloButton.secondary(
            label: l10n.schoolCalendarAdd,
            icon: Icons.add_rounded,
            size: size,
            fullWidth: compact,
            onPressed: add,
          );
    final publishButton = publish == null
        ? null
        : EteeloButton.primary(
            label: l10n.schoolCalendarPublish,
            icon: Icons.send_outlined,
            size: size,
            fullWidth: compact,
            onPressed: publish,
          );
    final Widget body = compact
        ? _compact(l10n, help, addButton, publishButton)
        : _wide(l10n, size, help, addButton, publishButton);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.calendarUpcomingStart,
            AppColors.calendarUpcomingMid,
            AppColors.calendarUpcomingEnd,
          ],
        ),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.calendarUpcomingBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          if (notice case final notice?) ...[
            const SizedBox(height: AppSpacing.md),
            notice,
          ],
        ],
      ),
    );
  }

  Widget _compact(
    AppLocalizations l10n,
    Widget help,
    Widget? addButton,
    Widget? publishButton,
  ) {
    final icons = [
      if (actions.print case final print?)
        CalendarRoundIconButton(
          icon: Icons.print_outlined,
          tooltip: l10n.schoolCalendarPrint,
          onPressed: print,
        ),
      if (actions.officialDocument case final document?)
        CalendarRoundIconButton(
          icon: Icons.description_outlined,
          tooltip: l10n.schoolCalendarOfficialDocument,
          onPressed: document,
        ),
      if (actions.duplicate case final duplicate?)
        CalendarRoundIconButton(
          icon: Icons.copy_all_outlined,
          tooltip: l10n.schoolCalendarDuplicateNextYear,
          onPressed: duplicate,
        ),
    ];
    final row = [...icons, ?addButton, ?publishButton];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        help,
        if (row.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final (i, child) in row.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                if (child is CalendarRoundIconButton)
                  child
                else
                  Expanded(child: child),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _wide(
    AppLocalizations l10n,
    EteeloButtonSize size,
    Widget help,
    Widget? addButton,
    Widget? publishButton,
  ) {
    final buttons = [
      if (actions.print case final print?)
        EteeloButton.ghost(
          label: l10n.schoolCalendarPrint,
          icon: Icons.print_outlined,
          size: size,
          fullWidth: false,
          onPressed: print,
        ),
      if (actions.officialDocument case final document?)
        EteeloButton.secondary(
          label: l10n.schoolCalendarOfficialDocument,
          icon: Icons.description_outlined,
          size: size,
          fullWidth: false,
          onPressed: document,
        ),
      if (actions.duplicate case final duplicate?)
        EteeloButton.secondary(
          label: l10n.schoolCalendarDuplicate,
          icon: Icons.copy_all_outlined,
          size: size,
          fullWidth: false,
          onPressed: duplicate,
        ),
      ?addButton,
      ?publishButton,
    ];
    // L'aide garde au moins 200 dp (maquette : `flex: 1 1 200px`) ; les
    // gestes prennent leur largeur, à droite, et passent à la ligne au-delà.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: help),
          if (buttons.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    (constraints.maxWidth -
                            AppDimensions.calendarHelpMinWidth -
                            AppSpacing.md)
                        .clamp(0, double.infinity),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: buttons,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
