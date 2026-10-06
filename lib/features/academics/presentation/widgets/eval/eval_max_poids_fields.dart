import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Maximum et poids côte à côte, dans la modale de création (spec §3).
class EvalMaxPoidsFields extends StatelessWidget {
  final TextEditingController maxController;
  final TextEditingController poidsController;
  final VoidCallback onChanged;

  const EvalMaxPoidsFields({
    super.key,
    required this.maxController,
    required this.poidsController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EteeloTextInput(
            label: l10n.evalCreateFieldMax,
            controller: maxController,
            required: true,
            keyboardType: EteeloTextInputType.number,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: EteeloTextInput(
            label: l10n.evalCreateFieldPoids,
            controller: poidsController,
            required: true,
            keyboardType: EteeloTextInputType.number,
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}
