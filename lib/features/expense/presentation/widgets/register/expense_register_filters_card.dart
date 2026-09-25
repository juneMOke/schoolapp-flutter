import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_period_bar.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_type_chips.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les strates 1 et 2 du registre (spec « Anatomie ») dans une seule carte :
/// la période et les filtres forment une seule question — « quel périmètre ? ».
/// « Nouvelle dépense » est en bout de barre : enregistrer ne doit jamais
/// demander de faire défiler la page.
class ExpenseRegisterFiltersCard extends StatefulWidget {
  final ExpensePeriod period;
  final ExpenseDateRange range;
  final List<ExpenseType> types;
  final ExpenseQuery query;
  final Map<String, int> typeCounts;
  final ValueChanged<ExpenseGranularity> onGranularityChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;
  final ValueChanged<String> onToggleType;
  final VoidCallback onClearTypes;
  final ValueChanged<ExpenseStatus?> onStatusChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onCreate;

  const ExpenseRegisterFiltersCard({
    super.key,
    required this.period,
    required this.range,
    required this.types,
    required this.query,
    required this.typeCounts,
    required this.onGranularityChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    required this.onToggleType,
    required this.onClearTypes,
    required this.onStatusChanged,
    required this.onTextChanged,
    required this.onCreate,
  });

  @override
  State<ExpenseRegisterFiltersCard> createState() =>
      _ExpenseRegisterFiltersCardState();
}

class _ExpenseRegisterFiltersCardState
    extends State<ExpenseRegisterFiltersCard> {
  late final TextEditingController _search = TextEditingController(
    text: widget.query.text,
  );

  @override
  void didUpdateWidget(covariant ExpenseRegisterFiltersCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un contrôleur survit à l'oubli de sa valeur par le cubit : « Réinitialiser
    // les filtres » doit aussi vider le champ, sinon il afficherait une
    // recherche que le calcul ne connaît plus.
    if (widget.query.text != _search.text) _search.text = widget.query.text;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpenseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingS,
            children: [
              ExpensePeriodBar(
                period: widget.period,
                range: widget.range,
                onGranularityChanged: widget.onGranularityChanged,
                onPrevious: widget.onPrevious,
                onNext: widget.onNext,
                onCurrent: widget.onCurrent,
              ),
              PermissionGate.access(
                kExpenseWriteAccess,
                child: EteeloButton.primary(
                  label: l10n.expenseNewAction,
                  icon: Icons.add,
                  onPressed: widget.onCreate,
                  fullWidth: false,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
            child: Divider(height: 1, color: AppColors.border),
          ),
          ExpenseTypeChips(
            types: widget.types,
            selected: widget.query.typeIds,
            counts: widget.typeCounts,
            onToggle: widget.onToggleType,
            onClear: widget.onClearTypes,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingS,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _StatusFilter(
                selected: widget.query.status,
                onChanged: widget.onStatusChanged,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.expenseFormDialogMaxWidth,
                ),
                child: EteeloTextInput(
                  controller: _search,
                  label: l10n.expenseSearchLabel,
                  placeholder: l10n.expenseSearchPlaceholder,
                  capitalization: EteeloTextCapitalization.none,
                  onChanged: widget.onTextChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Toutes · Payée · Non payée — généré depuis les statuts, pour qu'un statut
/// ajouté en V2 n'ait pas à toucher l'écran.
class _StatusFilter extends StatelessWidget {
  final ExpenseStatus? selected;
  final ValueChanged<ExpenseStatus?> onChanged;

  const _StatusFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseStatusTitle.toUpperCase(),
          style: AppTextStyles.tableHeader.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        SegmentedTabFilter<String>(
          semanticsLabel: l10n.expenseStatusTitle,
          selected: selected?.wireValue ?? '',
          onSelected: (value) =>
              onChanged(value.isEmpty ? null : ExpenseStatus.fromWire(value)),
          options: [
            SegmentedTabOption(label: l10n.expenseStatusAll, value: ''),
            for (final status in ExpenseStatus.values)
              SegmentedTabOption(
                label: expenseStatusLabel(l10n, status),
                value: status.wireValue,
              ),
          ],
        ),
      ],
    );
  }
}
