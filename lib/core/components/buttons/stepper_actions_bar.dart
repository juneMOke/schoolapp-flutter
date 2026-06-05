import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Barre d'actions responsive pour steppers : navigation à gauche, indicateur
/// d'état au centre, actions de fin à droite (PARCOURS 21).
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth <= AppBreakpoints.detailCompactMax;
        final hasLeadingAction = leadingActionBuilder != null;
        final center = centerBuilder?.call(context);
        final trailingActions = trailingActionBuilders
            .map((builder) => builder(context))
            .toList(growable: false);
        final trailingWrap = trailingActions.isEmpty
            ? null
            : Wrap(
                alignment: WrapAlignment.end,
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: trailingActions,
              );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (center != null) ...[
                Center(child: center),
                const SizedBox(height: AppDimensions.spacingS),
              ],
              if (hasLeadingAction)
                Align(
                  alignment: Alignment.centerLeft,
                  child: leadingActionBuilder!(context),
                ),
              if (hasLeadingAction && trailingWrap != null)
                const SizedBox(height: AppDimensions.spacingS),
              ?trailingWrap,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: hasLeadingAction
                    ? leadingActionBuilder!(context)
                    : const SizedBox.shrink(),
              ),
            ),
            if (center != null) Flexible(child: center),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailingWrap ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
