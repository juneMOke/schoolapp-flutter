import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_hint_panel.dart';

/// L'aide de la case au focus : au tactile, l'appui long sélectionne le texte
/// avant que l'info-bulle ne s'ouvre. Elle ne fait que lire — la case, sa
/// frappe et son écriture ne la connaissent pas.
///
/// Posée sous la grille, elle ne prend aucune place : tant qu'une case a le
/// focus, sa surface flotte en bas de la page visible, au-dessus du clavier,
/// à la largeur de la grille. Une grille longue ou un clavier ouvert ne la
/// cachent pas, et une aide sur trois lignes ne change pas la page. La case
/// au focus remonte au-dessus d'elle (et son `scrollPadding` en tient compte).
///
/// Hors de la sémantique : la case porte déjà son aide au lecteur d'écran.
class CoteGridHintBand extends StatefulWidget {
  final CoteGridContext grid;

  const CoteGridHintBand({super.key, required this.grid});

  @override
  State<CoteGridHintBand> createState() => _CoteGridHintBandState();
}

/// La place de la surface dans l'overlay : bord gauche, largeur, et distance
/// au bas de l'overlay.
typedef _Place = ({double left, double width, double bottom});

class _CoteGridHintBandState extends State<CoteGridHintBand>
    with WidgetsBindingObserver {
  final _portal = OverlayPortalController();
  final _panelKey = GlobalKey(debugLabel: 'CoteGridHintPanel');
  final _place = ValueNotifier<_Place?>(null);
  ({CoteCours cours, CoteColumn column})? _focused;
  ScrollableState? _page;
  ScrollPosition? _position;
  FlutterView? _view;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFocusChanged());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
    _page = Scrollable.maybeOf(context, axis: Axis.vertical);
    final position = _page?.position;
    if (position == _position) return;
    _position?.removeListener(_measure);
    _position = position?..addListener(_measure);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    _position?.removeListener(_measure);
    _place.dispose();
    super.dispose();
  }

  /// Le clavier s'ouvre ou se ferme, la fenêtre change.
  @override
  void didChangeMetrics() => _measureAfterFrame(reveal: true);

  void _onFocusChanged() {
    if (!mounted) return;
    final focused = widget.grid.registry.focusedCell;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    if (focused == null) {
      _portal.hide();
    } else {
      _portal.show();
      // La mise en page du cadre précédent vaut encore : la surface paraît
      // dès le prochain, puis la case se révèle au-dessus d'elle.
      _measure();
      _measureAfterFrame(reveal: true);
    }
  }

  void _measureAfterFrame({bool reveal = false, int tries = 3}) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measure(reveal: reveal, tries: tries),
    );
  }

  /// Place la surface au bas de la page visible et au-dessus du clavier. Avec
  /// [reveal], remonte la case au focus si la surface la couvre.
  void _measure({bool reveal = false, int tries = 0}) {
    if (!mounted || _focused == null) return;
    final anchor = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (anchor == null || overlay == null) return;
    if (!anchor.attached || !anchor.hasSize || !overlay.hasSize) return;
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    var left = origin.dx;
    var right = left + anchor.size.width;
    var bottom = overlay.size.height;
    final page = _page?.context.findRenderObject();
    if (page is RenderBox && page.attached && page.hasSize) {
      final visible = MatrixUtils.transformRect(
        page.getTransformTo(overlay),
        Offset.zero & page.size,
      );
      bottom = math.min(bottom, visible.bottom);
      left = math.max(left, visible.left);
      right = math.min(right, visible.right);
    }
    final view = _view;
    if (view != null) {
      final ratio = view.devicePixelRatio;
      final keyboardTop = overlay.globalToLocal(
        Offset(0, (view.physicalSize.height - view.viewInsets.bottom) / ratio),
      );
      bottom = math.min(bottom, keyboardTop.dy);
    }
    final place = right <= left
        ? null
        : (
            left: left,
            width: right - left,
            bottom: math.max(0.0, overlay.size.height - bottom),
          );
    if (place != _place.value) _place.value = place;

    final panel = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (place == null || panel == null || !panel.hasSize) {
      if (reveal && tries > 0) {
        _measureAfterFrame(reveal: true, tries: tries - 1);
      }
      return;
    }
    widget.grid.hintBandHeight.value = panel.size.height;
    if (reveal) _reveal(overlay, bottom - panel.size.height);
  }

  /// La case au focus passe au-dessus de la surface, dont le haut est à
  /// [bandTop] dans l'overlay.
  void _reveal(RenderBox overlay, double bandTop) {
    final focused = _focused;
    final position = _position;
    if (focused == null || position == null) return;
    final node = widget.grid.registry.nodeFor(focused.cours, focused.column);
    final cell = node.context?.findRenderObject() as RenderBox?;
    if (cell == null || !cell.attached || !cell.hasSize) return;
    final rect = MatrixUtils.transformRect(
      cell.getTransformTo(overlay),
      Offset.zero & cell.size,
    );
    final overlap = rect.bottom + AppSpacing.lg - bandTop;
    if (overlap <= 0) return;
    final target = (position.pixels + overlap).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) position.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focused;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => ValueListenableBuilder<_Place?>(
        valueListenable: _place,
        builder: (context, place, _) {
          if (place == null || focused == null) return const SizedBox.shrink();
          return Positioned(
            left: place.left,
            width: place.width,
            bottom: place.bottom,
            // Elle ne prend ni tap ni défilement : ce qu'elle couvre reste
            // atteignable.
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: CoteGridHintPanel(
                  key: _panelKey,
                  classe: widget.grid.classe,
                  studentId: widget.grid.studentId,
                  cours: focused.cours,
                  column: focused.column,
                ),
              ),
            ),
          );
        },
      ),
      child: const SizedBox(height: 0),
    );
  }

  @override
  void didUpdateWidget(CoteGridHintBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La grille s'est remise en page (rubrique repliée, autre largeur).
    _measureAfterFrame();
  }
}
