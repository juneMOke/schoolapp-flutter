import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';

/// Tient des filtres d'écran ([current]) d'accord avec la requête de son
/// adresse (`?categorie=…&tri=…`), dans les deux sens — le pendant de
/// `LocationTabSync` pour plusieurs paramètres.
///
/// - **Filtres → adresse** : un filtre changé s'inscrit ; F5 le retrouve,
///   l'adresse se partage, Précédent revient aux filtres d'avant.
/// - **Adresse → filtres** : au montage (F5, lien) et à chaque changement
///   d'adresse (Précédent, Suivant), [onLocation] reçoit les valeurs lues.
///
/// Une valeur `null` est la valeur par défaut de l'écran : elle n'apparaît
/// pas dans l'adresse. Seules les clés de [current] sont lues et écrites ; le
/// reste de la requête (l'onglet d'un autre widget) n'est pas touché.
///
/// L'écran garde ses filtres où il les a (cubit) : ce widget ne fait que les
/// relier à l'adresse. Sans routeur, ou poussé par-dessus une autre page, il
/// ne fait rien.
///
/// ⚠️ Pas de texte libre ici : chaque frappe deviendrait une entrée
/// d'historique.
class LocationParamsSync extends StatefulWidget {
  final Map<String, String?> current;
  final ValueChanged<Map<String, String?>> onLocation;
  final Widget child;

  const LocationParamsSync({
    super.key,
    required this.current,
    required this.onLocation,
    required this.child,
  });

  @override
  State<LocationParamsSync> createState() => _LocationParamsSyncState();
}

class _LocationParamsSyncState extends State<LocationParamsSync> {
  GoRouter? _router;
  bool _bound = false;

  /// Une écriture de l'écran attend le prochain rendu. Tant qu'elle n'est pas
  /// partie, l'adresse est plus ancienne que l'écran : un autre lien de la
  /// même page qui écrit d'abord (l'onglet, puis le mois) réveillerait ce
  /// widget sur l'ancienne valeur, et il défairait le geste qu'on vient de
  /// faire.
  bool _writePending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) return;
    _bound = true;
    _router = LocationQuery.ownedBy(context)
      ?..routerDelegate.addListener(_followLocation);
    // Après le premier rendu : l'écran a monté ses filtres. Une adresse nue
    // ne les change pas — l'écran ouvre sur ses valeurs par défaut.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _followLocation(bareMeansDefault: false),
    );
  }

  @override
  void didUpdateWidget(covariant LocationParamsSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Après la reconstruction : changer d'adresse la relance.
    if (!mapEquals(oldWidget.current, widget.current)) {
      _writePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _writeLocation());
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_followLocation);
    super.dispose();
  }

  Map<String, String?> _read(GoRouter router) => {
    for (final key in widget.current.keys) key: LocationQuery.read(router, key),
  };

  /// [bareMeansDefault] : revenu à l'adresse nue (Précédent), l'écran revient
  /// à ses valeurs par défaut.
  void _followLocation({bool bareMeansDefault = true}) {
    final router = _router;
    if (!mounted || router == null || _writePending) return;
    final read = _read(router);
    if (!bareMeansDefault && read.values.every((value) => value == null)) {
      return;
    }
    if (mapEquals(read, widget.current)) return;
    widget.onLocation(read);
  }

  void _writeLocation() {
    _writePending = false;
    final router = _router;
    if (!mounted || router == null) return;
    if (mapEquals(_read(router), widget.current)) return;
    LocationQuery.write(router, widget.current);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
