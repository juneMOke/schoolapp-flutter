import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_pickers.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le jour et l'heure du décaissement d'une déclaration — à l'heure de
/// l'école, jamais dans le futur. Le jour **est** la date de la dépense
/// (F47) : il n'y a pas d'autre date à saisir.
class ExpenseDisbursementFields extends StatefulWidget {
  final DateTime day;
  final TimeOfDay time;

  /// Aujourd'hui, à l'heure de l'école : la borne du calendrier.
  final DateTime today;
  final ValueChanged<DateTime> onDayChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const ExpenseDisbursementFields({
    super.key,
    required this.day,
    required this.time,
    required this.today,
    required this.onDayChanged,
    required this.onTimeChanged,
  });

  @override
  State<ExpenseDisbursementFields> createState() =>
      _ExpenseDisbursementFieldsState();
}

class _ExpenseDisbursementFieldsState extends State<ExpenseDisbursementFields> {
  final TextEditingController _time = TextEditingController();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showEteeloTimePicker(
      context: context,
      initialTime: widget.time,
    );
    if (!mounted || picked == null) return;
    widget.onTimeChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _time.text = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(widget.time, alwaysUse24HourFormat: true);
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingM,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.expenseFormDateMinWidth,
            maxWidth: AppDimensions.expenseFormDateMaxWidth,
          ),
          child: EteeloDateInput(
            label: l10n.expenseDisbursedOnLabel,
            required: true,
            value: widget.day,
            onChanged: (value) {
              if (value != null) widget.onDayChanged(value);
            },
            firstDate: DateTime(widget.today.year - 1),
            lastDate: widget.today,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.expenseFormTimeMinWidth,
            maxWidth: AppDimensions.expenseFormTimeMaxWidth,
          ),
          child: EteeloTextInput(
            controller: _time,
            label: l10n.expenseDisbursedAtLabel,
            required: true,
            readOnly: true,
            capitalization: EteeloTextCapitalization.none,
            prefix: const Icon(Icons.schedule),
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }
}
