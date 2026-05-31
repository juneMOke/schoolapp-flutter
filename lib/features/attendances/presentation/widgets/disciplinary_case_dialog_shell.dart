import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

class DisciplinaryCaseDialogShell extends StatefulWidget {
  final Widget child;
  final double maxWidth;
  final double heightFactor;

  const DisciplinaryCaseDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.heightFactor = 0.85,
  });

  @override
  State<DisciplinaryCaseDialogShell> createState() =>
      _DisciplinaryCaseDialogShellState();
}

class _DisciplinaryCaseDialogShellState
    extends State<DisciplinaryCaseDialogShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: AppMotion.outCurve),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: AppMotion.outCurve),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - bottomInset;
    final maxHeight = availableHeight * widget.heightFactor;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingL,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.sectionCardRadius,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth,
                maxHeight: maxHeight,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
