import 'package:flutter/widgets.dart';

/// Relaie les passages **premier plan / arrière-plan** de l'application vers la
/// boucle de synchronisation (`SyncStatusCubit`).
///
/// Existe comme widget dédié, et non comme quelques lignes dans l'état racine
/// de `main.dart`, pour une raison précise : un déclencheur de synchro qui
/// n'est **pas branché** ne se voit sur aucun écran et ne casse aucun test.
/// Isolé ici, le câblage se vérifie pour ce qu'il est — un état de cycle de vie
/// entre, un appel sort.
///
/// **Ne porte aucune politique.** Ni la garde de session, ni l'anti-rafale, ni
/// l'ordre du cycle, ni la période du battement : tout cela appartient au cubit
/// et aux rappels que lui passe la racine. Ce widget ne connaît que le cycle de
/// vie Flutter.
///
/// Transparent dans l'arbre : rend [child] tel quel.
class SyncLifecycleObserver extends StatefulWidget {
  /// Appelé à **chaque** passage à [AppLifecycleState.resumed]. À la charge de
  /// l'appelant d'être idempotent et bon marché : sur Android, un simple
  /// aller-retour vers la liste des applications récentes suffit à le
  /// déclencher.
  final VoidCallback onResume;

  /// Appelé dès que l'application **cesse** d'être au premier plan, quelle que
  /// soit la profondeur du retrait.
  ///
  /// `inactive` compte, au même titre que `paused`, `hidden` et `detached` :
  /// distinguer les degrés coûterait un état supplémentaire pour un gain nul,
  /// puisque le seul consommateur — l'arrêt du battement — se rétablit d'un
  /// `Timer` recréé au retour. Mieux vaut suspendre une seconde de trop que
  /// laisser tourner une boucle réseau hors de tout usage.
  final VoidCallback onPause;

  final Widget child;

  const SyncLifecycleObserver({
    super.key,
    required this.onResume,
    required this.onPause,
    required this.child,
  });

  @override
  State<SyncLifecycleObserver> createState() => _SyncLifecycleObserverState();
}

class _SyncLifecycleObserverState extends State<SyncLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Binaire, délibérément : `resumed` d'un côté, tout le reste de l'autre.
    // Un quatrième état ajouté par Flutter tombera donc du côté prudent.
    if (state == AppLifecycleState.resumed) {
      widget.onResume();
      return;
    }
    widget.onPause();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
