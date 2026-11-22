import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le montant d'« a payé au moins » (I8) : chiffres seulement, saisi en
/// unités de la devise du périmètre, rendu au parent **en centimes** à chaque
/// chiffre ; vide ⇒ `null`.
///
/// ⚠️ Le contrôleur survit à l'oubli du montant par le parent (adresse
/// relue, frais changés) : il se resynchronise quand [thresholdInCents]
/// change de l'extérieur.
class RecouvrementRuleAmountField extends StatefulWidget {
  final int? thresholdInCents;
  final String? currency;
  final VoidCallback onFocused;
  final ValueChanged<int?> onChanged;

  const RecouvrementRuleAmountField({
    super.key,
    required this.thresholdInCents,
    required this.currency,
    required this.onFocused,
    required this.onChanged,
  });

  /// Neuf chiffres : un milliard d'unités, loin de tout frais réel et sous
  /// la borne d'un entier sur le fil.
  static const maxDigits = 9;

  /// Centimes par unité saisie : les deux devises se comptent en centimes.
  static const centsPerUnit = 100;

  static String textOf(int? cents) =>
      cents == null ? '' : (cents ~/ centsPerUnit).toString();

  static int? centsOf(String text) {
    final units = int.tryParse(text);
    return units == null ? null : units * centsPerUnit;
  }

  @override
  State<RecouvrementRuleAmountField> createState() =>
      _RecouvrementRuleAmountFieldState();
}

class _RecouvrementRuleAmountFieldState
    extends State<RecouvrementRuleAmountField> {
  late final _controller = TextEditingController(
    text: RecouvrementRuleAmountField.textOf(widget.thresholdInCents),
  );
  final _focus = FocusNode(debugLabel: 'rule-amount');

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) widget.onFocused();
    });
  }

  @override
  void didUpdateWidget(RecouvrementRuleAmountField old) {
    super.didUpdateWidget(old);
    final typed = RecouvrementRuleAmountField.centsOf(_controller.text);
    if (widget.thresholdInCents != typed) {
      _controller.text = RecouvrementRuleAmountField.textOf(
        widget.thresholdInCents,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = widget.currency;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        // Dans une colonne étroite (trois choix dès 600 reçus), le champ cède
        // de sa largeur plutôt que de déborder.
        Flexible(
          child: SizedBox(
            width: AppDimensions.recoveryStudentsAmountFieldWidth,
            child: EteeloTextInput(
              controller: _controller,
              focusNode: _focus,
              label: l10n.recoveryStudentsRuleAmountLabel,
              hideLabel: true,
              keyboardType: EteeloTextInputType.number,
              capitalization: EteeloTextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  RecouvrementRuleAmountField.maxDigits,
                ),
              ],
              onChanged: (text) =>
                  widget.onChanged(RecouvrementRuleAmountField.centsOf(text)),
            ),
          ),
        ),
        if (currency != null)
          Text(
            MoneyFormat.symbolOf(currency),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
