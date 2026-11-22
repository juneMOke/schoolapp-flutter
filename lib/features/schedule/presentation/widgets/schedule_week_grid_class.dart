part of 'schedule_week_grid.dart';

/// Le cadre d'une grille de classe (EDT §4.6 D) : bord chaud, et sous la
/// largeur mini la semaine défile de côté — ascenseur visible, fondu sur le
/// bord droit et bouton « Suite » qui avance d'un écran (I14). La gouttière
/// des heures reste figée : chaque ligne la translate du défilement.
class _ClassGridFrame extends StatefulWidget {
  final double width;
  final List<Widget> Function(ScrollController frozen) builder;

  const _ClassGridFrame({required this.width, required this.builder});

  @override
  State<_ClassGridFrame> createState() => _ClassGridFrameState();
}

class _ClassGridFrameState extends State<_ClassGridFrame> {
  final _controller = ScrollController();
  bool _overflow = false;
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_measure);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _ClassGridFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final overflow = position.maxScrollExtent > 0;
    final more = overflow && position.pixels < position.maxScrollExtent - 1;
    if (more != _more || overflow != _overflow) {
      setState(() {
        _more = more;
        _overflow = overflow;
      });
    }
  }

  void _next() {
    final position = _controller.position;
    final target = (position.pixels + position.viewportDimension * 0.8).clamp(
      0.0,
      position.maxScrollExtent,
    );
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _controller.jumpTo(target);
    } else {
      unawaited(
        _controller.animateTo(
          target,
          duration: AppMotion.layout,
          curve: AppMotion.outCurve,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.timetableWarmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Scrollbar(
            controller: _controller,
            thumbVisibility: _overflow,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.builder(_controller),
                ),
              ),
            ),
          ),
          if (_more) ...[
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: AppDimensions.timetableGridFadeWidth,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.surfaceRaised.withValues(alpha: 0),
                        AppColors.surfaceRaised,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: AppSpacing.sm,
              child: Center(
                child: Tooltip(
                  message: l10n.classTimetableGridMoreHint,
                  child: OutlinedButton.icon(
                    onPressed: _next,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right, size: AppSpacing.lg),
                    label: Text(l10n.classTimetableGridMore),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        AppDimensions.minTouchTarget,
                        AppDimensions.minTouchTarget,
                      ),
                      foregroundColor: AppColors.timetableWarmInk,
                      backgroundColor: AppColors.surfaceRaised,
                      side: const BorderSide(
                        color: AppColors.timetableWarmBorder,
                      ),
                      shape: const StadiumBorder(),
                      textStyle: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Garde son enfant au bord gauche du cadre pendant que la grille défile.
class _Frozen extends StatelessWidget {
  final ScrollController controller;
  final Widget child;

  const _Frozen({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => Transform.translate(
      offset: Offset(controller.hasClients ? controller.offset : 0, 0),
      child: child,
    ),
    child: child,
  );
}

/// Le créneau libre d'un brouillon de classe : tirets neutres à 60 %, qui
/// s'allument en terre cuite au survol ou au dépôt (« Déposer »).
class _QuietFreeSlot extends StatelessWidget {
  final bool lit;
  final bool dropping;
  final String label;

  const _QuietFreeSlot({
    required this.lit,
    required this.dropping,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ink = lit ? AppColors.terreCuite : AppColors.textMuted;
    return Opacity(
      opacity: lit ? 1 : AppDimensions.timetableFreeSlotOpacity,
      child: EteeloDashedContainer(
        backgroundColor: lit
            ? AppColors.timetableWarmSurfaceDeep
            : AppColors.surfaceRaised,
        borderColor: lit ? AppColors.terreCuite : AppColors.borderStrong,
        borderRadius: AppRadius.brMd,
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: AppSpacing.lg, color: ink),
              if (dropping) ...[
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(color: ink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
