import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/publish_calendar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/selection/checkable_row.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O3 — dupliquer vers l'année suivante (CAL-R8). Rend les natures à
/// reprendre ; le décalage de 52 semaines est calculé par le serveur.
class DuplicateCalendarDialog extends StatefulWidget {
  final String sourceYear;
  final String targetYear;
  final int eventCount;
  final int windowCount;

  const DuplicateCalendarDialog({
    super.key,
    required this.sourceYear,
    required this.targetYear,
    required this.eventCount,
    required this.windowCount,
  });

  /// Les événements de l'école ; les interrogations ont leur propre case.
  static const eventNatures = [
    CalendarNature.exam,
    CalendarNature.holidayBreak,
    CalendarNature.schoolLife,
  ];

  @override
  State<DuplicateCalendarDialog> createState() => _DuplicateState();
}

class _DuplicateState extends State<DuplicateCalendarDialog> {
  bool _events = true;
  bool _windows = true;

  List<CalendarNature> get _natures => [
    if (_events) ...DuplicateCalendarDialog.eventNatures,
    if (_windows) CalendarNature.assessment,
  ];

  void _submit() => Navigator.of(context).pop(_natures);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloFormDialog(
      eyebrow: l10n.schoolCalendarDuplicateEyebrow(widget.sourceYear),
      title: l10n.schoolCalendarDuplicateFor(widget.targetYear),
      onSubmit: _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckableRow(
            value: _events,
            onChanged: (v) => setState(() => _events = v),
            child: CalendarDialogLine(
              l10n.schoolCalendarDuplicateEvents,
              l10n.schoolCalendarDuplicateEventsCount(widget.eventCount),
            ),
          ),
          CheckableRow(
            value: _windows,
            onChanged: (v) => setState(() => _windows = v),
            child: CalendarDialogLine(
              l10n.schoolCalendarDuplicateWindows,
              l10n.schoolCalendarDuplicateWindowsCount(widget.windowCount),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EteeloNotice.warning(
            l10n.schoolCalendarDuplicateRule(widget.sourceYear),
          ),
        ],
      ),
      actions: [
        SecondaryButton(
          label: l10n.schoolCalendarFormCancel,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          label: l10n.schoolCalendarDuplicate,
          fullWidth: false,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// O4 — un nouveau calendrier, pour une année libre seulement (A5).
class NewCalendarDialog extends StatefulWidget {
  final List<({String yearLabel, FrameworkState framework})> years;

  const NewCalendarDialog({super.key, required this.years});

  @override
  State<NewCalendarDialog> createState() => _NewState();
}

class _NewState extends State<NewCalendarDialog> {
  String? _year;

  @override
  void initState() {
    super.initState();
    _year = widget.years.isEmpty ? null : widget.years.first.yearLabel;
  }

  void _submit() {
    if (_year != null) Navigator.of(context).pop(_year);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = [
      for (final y in widget.years)
        if (y.yearLabel == _year) y,
    ];
    return EteeloFormDialog(
      title: l10n.schoolCalendarNew,
      onSubmit: _year == null ? null : _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.years.isEmpty)
            Text(l10n.schoolCalendarNewNoYear, style: AppTypography.bodyMedium)
          else
            EteeloSelectInput<String>(
              label: l10n.schoolCalendarNewYear,
              value: _year,
              onChanged: (v) => setState(() => _year = v),
              items: [
                for (final y in widget.years)
                  EteeloSelectItem(value: y.yearLabel, label: y.yearLabel),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          if (selected.isNotEmpty)
            EteeloNotice.warning(
              selected.single.framework == FrameworkState.integrated
                  ? l10n.schoolCalendarNewFrameworkReady(
                      selected.single.yearLabel,
                    )
                  : l10n.schoolCalendarNewFrameworkAwaited(
                      selected.single.yearLabel,
                    ),
            ),
          Text(l10n.schoolCalendarNewTip, style: AppTypography.bodySmall),
        ],
      ),
      actions: [
        SecondaryButton(
          label: l10n.schoolCalendarFormCancel,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          label: l10n.schoolCalendarNewCreate,
          fullWidth: false,
          onPressed: _year == null ? null : _submit,
        ),
      ],
    );
  }
}
