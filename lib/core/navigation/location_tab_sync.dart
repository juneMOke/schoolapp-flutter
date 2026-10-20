import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';

/// Tient l'onglet [current] d'un écran d'accord avec `?onglet=` dans son
/// adresse, dans les deux sens.
///
/// - **Onglet → adresse** : changer d'onglet l'inscrit ; F5 le retrouve,
///   l'adresse se partage, Précédent revient à l'onglet d'avant.
/// - **Adresse → onglet** : au montage (F5, lien) et à chaque changement
///   d'adresse (Précédent, Suivant), [onLocationTab] reçoit l'onglet lu.
///
/// L'écran garde son état d'onglet où il l'a (cubit, `setState`) : ce widget
/// ne fait que le relier à l'adresse. Sans routeur, il ne fait rien.
class LocationTabSync<T extends Enum> extends StatefulWidget {
  static const param = 'onglet';

  final List<T> values;
  final T current;
  final ValueChanged<T> onLocationTab;
  final Widget child;

  const LocationTabSync({
    super.key,
    required this.values,
    required this.current,
    required this.onLocationTab,
    required this.child,
  });

  @override
  State<LocationTabSync<T>> createState() => _LocationTabSyncState<T>();
}

class _LocationTabSyncState<T extends Enum> extends State<LocationTabSync<T>> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter.maybeOf(context)
      ?..routerDelegate.addListener(_followLocation);
    // Après le premier rendu : l'écran a monté son état d'onglet. Une
    // adresse nue ne le change pas — l'écran ouvre l'onglet qu'il veut.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _followLocation(bareMeansFirst: false),
    );
  }

  @override
  void didUpdateWidget(covariant LocationTabSync<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Après la reconstruction : changer d'adresse la relance.
    if (oldWidget.current != widget.current) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _writeLocation());
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_followLocation);
    super.dispose();
  }

  /// [bareMeansFirst] : revenu à l'adresse nue (Précédent depuis un autre
  /// onglet), l'écran revient au premier.
  void _followLocation({bool bareMeansFirst = true}) {
    final router = _router;
    if (!mounted || router == null) return;
    final name = LocationQuery.read(router, LocationTabSync.param);
    final tab = name == null
        ? (bareMeansFirst ? widget.values.first : null)
        : widget.values.where((value) => value.name == name).firstOrNull;
    if (tab != null && tab != widget.current) widget.onLocationTab(tab);
  }

  void _writeLocation() {
    final router = _router;
    if (!mounted || router == null) return;
    // Le premier onglet est l'adresse nue : `/home/paie` reste `/home/paie`.
    final name = widget.current == widget.values.first
        ? null
        : widget.current.name;
    if (LocationQuery.read(router, LocationTabSync.param) == name) return;
    LocationQuery.write(router, {LocationTabSync.param: name});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
