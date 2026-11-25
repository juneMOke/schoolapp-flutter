import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum ExpenseQueueTab { requests, visa }

/// Les deux files de la direction : les **demandes** à trancher, et les
/// **déclarations** à viser (v3). Deux onglets plutôt qu'une liste mêlée :
/// on n'y fait pas le même geste — accorder avant, contrôler après.
class ExpenseQueueTabs extends StatefulWidget {
  final int toVisaCount;
  final Widget requests;
  final Widget visa;

  const ExpenseQueueTabs({
    super.key,
    required this.toVisaCount,
    required this.requests,
    required this.visa,
  });

  @override
  State<ExpenseQueueTabs> createState() => _ExpenseQueueTabsState();
}

class _ExpenseQueueTabsState extends State<ExpenseQueueTabs> {
  ExpenseQueueTab _tab = ExpenseQueueTab.requests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = widget.toVisaCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedTabFilter<ExpenseQueueTab>(
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
          semanticsLabel: l10n.expenseQueueTitle,
          expand: true,
          options: [
            SegmentedTabOption(
              label: l10n.expenseQueueTabRequests,
              value: ExpenseQueueTab.requests,
              icon: Icons.approval_outlined,
            ),
            SegmentedTabOption(
              label: count == 0
                  ? l10n.expenseQueueTabVisa
                  : '${l10n.expenseQueueTabVisa} · $count',
              value: ExpenseQueueTab.visa,
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        switch (_tab) {
          ExpenseQueueTab.requests => widget.requests,
          ExpenseQueueTab.visa => widget.visa,
        },
      ],
    );
  }
}
