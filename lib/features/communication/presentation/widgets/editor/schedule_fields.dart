import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La date et l'heure d'un envoi programmé, **à l'heure de l'école** :
/// l'instant rendu est en UTC, comme l'API le stocke.
class ScheduleFields extends StatefulWidget {
  final DateTime instant;
  final DateTime now;
  final ValueChanged<DateTime>? onChanged;
  final String? errorText;

  const ScheduleFields({
    super.key,
    required this.instant,
    required this.now,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<ScheduleFields> createState() => _ScheduleFieldsState();
}

class _ScheduleFieldsState extends State<ScheduleFields> {
  final _time = TextEditingController();

  DateTime get _wall => SchoolTime.wallClock(widget.instant);

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  void _emit({DateTime? day, TimeOfDay? time}) {
    final wall = _wall;
    final at = time ?? TimeOfDay(hour: wall.hour, minute: wall.minute);
    widget.onChanged?.call(
      SchoolTime.instantAt(day: day ?? wall, hour: at.hour, minute: at.minute),
    );
  }

  Future<void> _pickTime() async {
    final wall = _wall;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: wall.hour, minute: wall.minute),
    );
    if (!mounted || picked == null) return;
    _emit(time: picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wall = _wall;
    _time.text = l10n.communicationClock(wall);
    final today = SchoolTime.today(widget.now);
    final enabled = widget.onChanged != null;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 200,
          child: EteeloDateInput(
            label: l10n.communicationScheduleDate,
            value: DateTime(wall.year, wall.month, wall.day),
            firstDate: today,
            lastDate: DateTime(today.year + 1, today.month, today.day),
            enabled: enabled,
            errorText: widget.errorText,
            onChanged: (day) {
              if (day != null) _emit(day: day);
            },
          ),
        ),
        SizedBox(
          width: 140,
          child: EteeloTextInput(
            controller: _time,
            label: l10n.communicationScheduleTime,
            readOnly: true,
            enabled: enabled,
            capitalization: EteeloTextCapitalization.none,
            prefix: const Icon(Icons.schedule, size: 18),
            onTap: enabled ? _pickTime : null,
          ),
        ),
      ],
    );
  }
}
