import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Barre d'actions responsive pour steppers (action précédente + actions de fin).
class StepperActionsBar extends StatelessWidget {
  final WidgetBuilder? leadingActionBuilder;
  final List<WidgetBuilder> trailingActionBuilders;

  const StepperActionsBar({
    super.key,
    this.leadingActionBuilder,
    required this.trailingActionBuilders,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth <= AppBreakpoints.detailCompactMax;
        final hasLeadingAction = leadingActionBuilder != null;
        final trailingActions = trailingActionBuilders
            .map((builder) => builder(context))
            .toList(growable: false);

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasLeadingAction)
                Align(
                  alignment: Alignment.centerLeft,
                  child: leadingActionBuilder!(context),
                ),
              if (hasLeadingAction && trailingActions.isNotEmpty)
                const SizedBox(height: AppDimensions.spacingS),
              if (trailingActions.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  children: trailingActions,
                ),
            ],
          );
        }

        return Row(
          children: [
            if (hasLeadingAction) leadingActionBuilder!(context),
            const Spacer(),
            if (trailingActions.isNotEmpty)
              Wrap(
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: trailingActions,
              ),
          ],
        );
      },
    );
  }
}
