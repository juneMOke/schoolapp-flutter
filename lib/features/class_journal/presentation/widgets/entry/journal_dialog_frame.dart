import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Le cadre des modales du journal : 720 dp de large, plein écran sous le
/// point de rupture.
class JournalDialogFrame extends StatelessWidget {
  final Widget child;

  const JournalDialogFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < AppDimensions.journalBreakpoint) {
      return Dialog.fullscreen(child: child);
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.journalModalWidth,
        ),
        child: child,
      ),
    );
  }
}
