import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Le pied d'une modale carte : ses actions côte à côte, de même largeur,
/// l'action principale à droite. Sous [AppDimensions.dialogActionsStackBelow],
/// elles s'empilent, l'action principale en tête — les libellés longs ne se
/// serrent jamais.
///
/// [actions] va de la plus discrète à la principale.
class EteeloDialogActions extends StatelessWidget {
  final List<Widget> actions;

  const EteeloDialogActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppDimensions.dialogActionsStackBelow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, action) in actions.reversed.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                action,
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final (i, action) in actions.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: action),
            ],
          ],
        );
      },
    ),
  );
}
