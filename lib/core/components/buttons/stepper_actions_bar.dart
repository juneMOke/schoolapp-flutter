import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Barre d'actions du stepper sur UNE seule ligne : navigation à gauche,
/// indicateur d'état (flexible) au centre, actions de fin à droite. Tous les
/// boutons restent en ligne (pas d'empilement vertical).
class StepperActionsBar extends StatelessWidget {
  final WidgetBuilder? leadingActionBuilder;
  final WidgetBuilder? centerBuilder;
  final List<WidgetBuilder> trailingActionBuilders;

  const StepperActionsBar({
    super.key,
    this.leadingActionBuilder,
    this.centerBuilder,
    required this.trailingActionBuilders,
  });

  @override
  Widget build(BuildContext context) {
    final leading = leadingActionBuilder?.call(context);
    final center = centerBuilder?.call(context);
    final trailing = trailingActionBuilders
        .map((builder) => builder(context))
        .toList(growable: false);

    return Row(
      children: [
        ?leading,
        // Indicateur d'état : occupe l'espace central restant et se compresse.
        Expanded(
          child: center == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: center),
                ),
        ),
        for (var i = 0; i < trailing.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDimensions.spacingS),
          trailing[i],
        ],
      ],
    );
  }
}
