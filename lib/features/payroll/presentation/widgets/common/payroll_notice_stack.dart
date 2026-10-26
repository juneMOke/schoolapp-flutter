import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une seule zone de bandeaux : le premier — le plus grave, l'appelant les
/// range — reste visible, les autres se replient sous « N autres points ».
/// Six bandeaux empilés repoussaient le livre sous la ligne de flottaison.
class PayrollNoticeStack extends StatefulWidget {
  /// Du plus grave au plus doux.
  final List<Widget> notices;

  const PayrollNoticeStack({super.key, required this.notices});

  @override
  State<PayrollNoticeStack> createState() => _PayrollNoticeStackState();
}

class _PayrollNoticeStackState extends State<PayrollNoticeStack> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final notices = widget.notices;
    if (notices.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final hidden = notices.length - 1;
    final shown = _expanded ? notices : notices.take(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, notice) in shown.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          notice,
        ],
        if (hidden > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: EteeloButton.ghost(
              label: _expanded
                  ? l10n.payrollNoticesLess
                  : l10n.payrollNoticesMore(hidden),
              icon: _expanded ? Icons.expand_less : Icons.expand_more,
              onPressed: () => setState(() => _expanded = !_expanded),
              fullWidth: false,
            ),
          ),
      ],
    );
  }
}
