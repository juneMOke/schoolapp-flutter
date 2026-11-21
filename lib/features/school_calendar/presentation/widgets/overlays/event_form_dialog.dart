import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_event_validation.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/calendar_overlay_frame.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/event_form_dates.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/event_form_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O2 — ajouter ou modifier un événement de l'école (plein écran sous 760).
/// Rend l'élément à enregistrer, `null` si l'on abandonne. Les erreurs de
/// CAL-R7 bloquent « Ajouter » ; les chevauchements avertissent seulement.
///
/// Remplacer un élément national ([replacing], ou un [initial] qui remplace
/// déjà) : la nature et la portée sont celles de l'élément national, figées ;
/// seuls l'intitulé, les dates et la note changent.
class EventFormDialog extends StatefulWidget {
  final String newId;

  /// L'année du calendrier, en sur-titre (« Calendrier 2025-2026 »).
  final String yearLabel;
  final CalendarElement? initial;
  final DateTime? initialDay;
  final Set<CalendarNature> natures;
  final CalendarScopeOptions scopes;
  final DateTime yearStart;
  final DateTime yearEnd;
  final List<CalendarElement> nationalElements;

  /// L'élément national à remplacer (un nouveau remplacement).
  final CalendarElement? replacing;

  const EventFormDialog({
    super.key,
    required this.newId,
    required this.yearLabel,
    required this.natures,
    required this.scopes,
    required this.yearStart,
    required this.yearEnd,
    required this.nationalElements,
    this.initial,
    this.initialDay,
    this.replacing,
  });

  static Future<CalendarElement?> show(
    BuildContext context,
    EventFormDialog dialog,
  ) => showEteeloAdaptiveDialog<CalendarElement>(
    context: context,
    builder: (_) => dialog,
  );

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late CalendarNature _nature;
  late final CalendarNature _initialNature;
  DateTime? _start;
  DateTime? _end;
  late CalendarScope _scope;

  /// Ce qu'on remplace : `null` pour un événement ordinaire.
  String? get _replaces => widget.replacing?.id ?? widget.initial?.replaces;

  /// Le point de départ : l'événement modifié, ou l'élément national copié.
  CalendarElement? get _base => widget.initial ?? widget.replacing;

  @override
  void initState() {
    super.initState();
    final initial = _base;
    _title = TextEditingController(text: initial?.title ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    // La première nature permise, dans l'ordre de la légende (maquette).
    _nature =
        initial?.nature ??
        CalendarNature.values.firstWhere(
          widget.natures.contains,
          orElse: () => widget.natures.first,
        );
    _initialNature = _nature;
    _start = initial?.startDate ?? widget.initialDay;
    _end = initial?.endDate ?? widget.initialDay;
    _scope = initial?.scope ?? const SchoolScope();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _title.text.trim() != (_base?.title ?? '') ||
      _note.text.trim() != (_base?.note ?? '') ||
      _start != (_base?.startDate ?? widget.initialDay) ||
      _end != (_base?.endDate ?? widget.initialDay) ||
      _nature != _initialNature ||
      _scope != (_base?.scope ?? const SchoolScope());

  CalendarEventCheck? get _check {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return null;
    return CalendarEventValidation.check(
      title: _title.text,
      nature: _nature,
      startDate: start,
      endDate: end,
      yearStart: widget.yearStart,
      yearEnd: widget.yearEnd,
      // L'élément remplacé ne s'avertit pas lui-même.
      nationalElements: [
        for (final e in widget.nationalElements)
          if (e.id != _replaces) e,
      ],
    );
  }

  void _submit() {
    final check = _check;
    if (check == null || !check.canSave) return;
    final note = _note.text.trim();
    final base = widget.initial;
    final element = CalendarElement(
      id: base?.id ?? widget.newId,
      source: CalendarSource.school,
      nature: _nature,
      title: _title.text.trim(),
      startDate: _start!,
      endDate: _end!,
      scope: _scope,
      note: note.isEmpty ? null : note,
      // Une modification retire la marque « à vérifier » (CAL-R9).
      createdBy: base?.createdBy,
      replaces: _replaces,
    );
    Navigator.of(context).pop(element);
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final abandon = await showAppConfirmationDialog(
      context: context,
      title: l10n.schoolCalendarAbandonTitle,
      message: l10n.schoolCalendarAbandonBody,
      confirmLabel: l10n.schoolCalendarAbandonConfirm,
      cancelLabel: l10n.schoolCalendarAbandonKeep,
      isDestructive: true,
    );
    if (abandon && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = _check;
    final canSave = check?.canSave ?? false;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: CalendarOverlayDialog(
        maxWidth: AppDimensions.calendarFormMaxWidth,
        eyebrow: l10n.schoolCalendarFormEyebrow(widget.yearLabel),
        title: widget.replacing != null
            ? l10n.schoolCalendarFormReplaceTitle
            : widget.initial == null
            ? l10n.schoolCalendarFormAddTitle
            : l10n.schoolCalendarFormEditTitle,
        onSubmit: canSave ? _submit : null,
        onClose: _cancel,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventNatureChoice(
              nature: _nature,
              natures: widget.natures,
              locked: _replaces != null,
              onChanged: (nature) => setState(() => _nature = nature),
            ),
            const SizedBox(height: AppSpacing.md),
            EteeloTextInput(
              controller: _title,
              label: l10n.schoolCalendarFormTitle,
              placeholder: l10n.schoolCalendarFormTitleHint(_nature.wire),
              required: true,
              capitalization: EteeloTextCapitalization.sentence,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            EventDatesBlock(
              nature: _nature,
              start: _start,
              end: _end,
              yearStart: widget.yearStart,
              yearEnd: widget.yearEnd,
              onStart: (d) => setState(() {
                _start = d;
                if (_end == null || (d != null && _end!.isBefore(d))) _end = d;
              }),
              onEnd: (d) => setState(() => _end = d),
            ),
            const SizedBox(height: AppSpacing.md),
            EventScopeSelect(
              scope: _scope,
              options: widget.scopes,
              onChanged: _replaces == null
                  ? (scope) => setState(() => _scope = scope)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            EventNoteField(controller: _note),
            const SizedBox(height: AppSpacing.md),
            EventFormMessages(
              check: check,
              yearStart: widget.yearStart,
              yearEnd: widget.yearEnd,
            ),
          ],
        ),
        actions: [
          EteeloButton.ghost(
            label: l10n.schoolCalendarFormCancel,
            fullWidth: false,
            size: EteeloButtonSize.regular,
            onPressed: _cancel,
          ),
          EteeloButton.primary(
            label: widget.replacing != null
                ? l10n.schoolCalendarReplace
                : widget.initial == null
                ? l10n.schoolCalendarAdd
                : l10n.schoolCalendarFormSave,
            icon: Icons.check_rounded,
            fullWidth: false,
            size: EteeloButtonSize.regular,
            onPressed: canSave ? _submit : null,
          ),
        ],
      ),
    );
  }
}
