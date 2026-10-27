import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une seule zone de bandeaux. Les **alertes** — l'argent parti sans trace,
/// un refus, un renvoi, ce qui bloque le geste suivant — restent toutes
/// visibles ; des **informations**, la première seulement, les autres se
/// replient sous « N autres points ». Six bandeaux empilés repoussaient le
/// livre sous la ligne de flottaison ; une alerte, elle, ne se cache jamais.
class PayrollNoticeStack extends StatefulWidget {
  final List<Widget> alerts;
  final List<Widget> infos;

  const PayrollNoticeStack({
    super.key,
    this.alerts = const [],
    this.infos = const [],
  });

  @override
  State<PayrollNoticeStack> createState() => _PayrollNoticeStackState();
}

class _PayrollNoticeStackState extends State<PayrollNoticeStack> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final infos = widget.infos;
    final hidden = infos.length - 1;
    final shown = [...widget.alerts, ...(_expanded ? infos : infos.take(1))];
    if (shown.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
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
