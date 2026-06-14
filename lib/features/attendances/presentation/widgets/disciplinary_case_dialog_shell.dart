import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
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
  bool _entryStarted = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    // reduced-motion : pas d'animation d'entrée, on saute à l'état final.
    if (MediaQuery.of(context).disableAnimations) {
      _entryController.value = 1.0;
    } else {
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion = mediaQuery.disableAnimations;

    // IMPORTANT : `Dialog` gère lui-même l'inset clavier (viewInsets) et le
    // safe area. On ne le soustrait donc PAS ici. L'ancienne version cumulait
    // une `AnimatedPadding(bottom: viewInsets)` ET un `maxHeight - viewInsets`,
    // ce qui pouvait réduire la zone de contenu jusqu'à une hauteur négative
    // (Flexible/scroll sans place) -> RenderBox sans taille -> crash au
    // hit-test sur téléphone. `maxHeight` n'est plus qu'un plafond.
    final maxHeight = mediaQuery.size.height * widget.heightFactor;

    // Sur téléphone, marge latérale réduite pour exploiter la largeur ; marge
    // confortable au-delà.
    final horizontalInset =
        mediaQuery.size.width < AppBreakpoints.dataTableCardsMax
        ? AppDimensions.spacingS
        : AppDimensions.spacingL;

    final dialog = Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: AppDimensions.spacingL,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: maxHeight,
        ),
        child: widget.child,
      ),
    );

    // reduced-motion : pas de transition d'entrée.
    if (reduceMotion) return dialog;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: dialog),
    );
  }
}
