import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Les titres des notes quand elles défilent : décalés comme les notes, entre
/// les mêmes filets. Hors du défileur, ils lui renvoient le glissé et la
/// molette de côté (Maj+molette) : saisir l'en-tête fait défiler les notes,
/// comme avant qu'il ne colle.
class CoteGridScrolledHeader extends StatefulWidget {
  /// La largeur de toutes les notes, celle du défileur.
  final double width;
  final ScrollController horizontal;
  final Widget child;

  const CoteGridScrolledHeader({
    super.key,
    required this.width,
    required this.horizontal,
    required this.child,
  });

  @override
  State<CoteGridScrolledHeader> createState() => _CoteGridScrolledHeaderState();
}

class _CoteGridScrolledHeaderState extends State<CoteGridScrolledHeader> {
  Drag? _drag;

  ScrollPosition? get _position =>
      widget.horizontal.hasClients ? widget.horizontal.position : null;

  void _dragStart(DragStartDetails details) {
    _drag = _position?.drag(details, () => _drag = null);
  }

  /// Le geste de la molette du défileur : de côté, ou vertical avec Maj à la
  /// souris. Le seul vertical reste à la page.
  void _signal(PointerSignalEvent event) {
    final position = _position;
    if (event is! PointerScrollEvent || position == null) return;
    final modifiers = ScrollConfiguration.of(context).pointerAxisModifiers;
    final flip =
        event.kind == PointerDeviceKind.mouse &&
        HardwareKeyboard.instance.logicalKeysPressed.any(modifiers.contains);
    final delta = flip ? event.scrollDelta.dy : event.scrollDelta.dx;
    if (delta == 0) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => position.pointerScroll(delta),
    );
  }

  @override
  void dispose() {
    _drag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final header = _header();
    return Listener(
      onPointerSignal: _signal,
      child: GestureDetector(
        supportedDevices: ScrollConfiguration.of(context).dragDevices,
        onHorizontalDragStart: _dragStart,
        onHorizontalDragUpdate: (details) => _drag?.update(details),
        onHorizontalDragEnd: (details) => _drag?.end(details),
        onHorizontalDragCancel: () => _drag?.cancel(),
        child: header,
      ),
    );
  }

  Widget _header() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: AppColors.borderStrong),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: widget.width,
          maxWidth: widget.width,
          child: Flow(
            delegate: _FollowNotes(widget.horizontal),
            children: [widget.child],
          ),
        ),
      ),
    );
  }
}

/// Le décalage se lit à la peinture, après la mise en page du défileur :
/// plus large, il ramène son décalage sans prévenir, et une lecture faite à
/// la construction gardait l'ancien.
class _FollowNotes extends FlowDelegate {
  final ScrollController horizontal;

  _FollowNotes(this.horizontal) : super(repaint: horizontal);

  @override
  void paintChildren(FlowPaintingContext context) {
    final dx = horizontal.hasClients ? -horizontal.offset : 0.0;
    context.paintChild(0, transform: Matrix4.translationValues(dx, 0, 0));
  }

  // Chaque reconstruction (largeur, forme de la grille) repeint : le
  // décalage a pu changer sans notification.
  @override
  bool shouldRepaint(_FollowNotes oldDelegate) => true;
}
