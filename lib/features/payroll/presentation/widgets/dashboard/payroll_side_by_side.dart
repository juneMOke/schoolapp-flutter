import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Deux cartes côte à côte dès qu'elles tiennent (largeur **reçue**), l'une
/// sous l'autre sinon — alignées en haut, jamais étirées à la même hauteur.
class PayrollSideBySide extends StatelessWidget {
  final Widget first;
  final Widget second;

  const PayrollSideBySide({
    super.key,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth >= AppBreakpoints.sideBySideMin
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: AppSpacing.lg),
              second,
            ],
          ),
  );
}
