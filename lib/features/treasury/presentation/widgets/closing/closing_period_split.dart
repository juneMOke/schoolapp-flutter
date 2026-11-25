import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La semaine ou le mois, et la journée touchée à côté quand la largeur
/// reçue le permet ([AppBreakpoints.treasuryPeriodSideBySideMin]).
///
/// Le volet de la journée a une largeur fixe
/// ([AppDimensions.treasuryDayPaneWidth]) : la période garde le reste, assez
/// pour son tableau « Jour par jour » entier — partagée en 5/9 · 4/9, elle
/// passait en cartes ou défilait de côté sur presque tous les portables.
///
/// Les deux colonnes défilent avec la page. Une journée choisie en bas du
/// mois remplit un volet resté en haut, hors de l'écran : la période appelle
/// alors `reveal`, qui ramène le volet à l'écran — au geste de choisir, même
/// la journée déjà affichée, et jamais sur les flèches du volet ni sur F5.
class ClosingPeriodSplit extends StatefulWidget {
  /// La période ; `sideBySide` dit si la journée s'ouvre à côté, `reveal`
  /// ramène le volet à l'écran après le choix d'une journée.
  final Widget Function(bool sideBySide, VoidCallback reveal) period;

  /// La journée, dans le volet de droite.
  final Widget pane;

  const ClosingPeriodSplit({
    super.key,
    required this.period,
    required this.pane,
  });

  @override
  State<ClosingPeriodSplit> createState() => _ClosingPeriodSplitState();
}

class _ClosingPeriodSplitState extends State<ClosingPeriodSplit> {
  final _paneKey = GlobalKey(debugLabel: 'closing-day-pane');

  /// Après le frame qui remplit le volet de la journée choisie.
  void _revealSoon() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());

  /// Ramène le haut du volet à l'écran s'il est passé au-dessus ; rien s'il
  /// est déjà visible.
  void _reveal() {
    final pane = _paneKey.currentContext;
    if (!mounted || pane == null) return;
    final still = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      pane,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      duration: still ? Duration.zero : AppMotion.standard,
      curve: AppMotion.outCurve,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sideBySide =
          constraints.maxWidth >= AppBreakpoints.treasuryPeriodSideBySideMin;
      final period = widget.period(sideBySide, _revealSoon);
      if (!sideBySide) return period;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: period),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            key: _paneKey,
            width: AppDimensions.treasuryDayPaneWidth,
            child: widget.pane,
          ),
        ],
      );
    },
  );
}
