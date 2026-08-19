import 'package:flutter/widgets.dart';

/// Relaie le retour de l'application au **premier plan** vers la boucle de
/// synchronisation (`SyncStatusCubit.syncOnResume`).
///
/// Existe comme widget dédié, et non comme trois lignes dans l'état racine de
/// `main.dart`, pour une raison précise : un déclencheur de synchro qui n'est
/// **pas branché** ne se voit sur aucun écran et ne casse aucun test. Isolé
/// ici, le câblage se vérifie pour ce qu'il est — un `resumed` entre, un appel
/// sort.
///
/// **Ne porte aucune politique.** Ni la garde de session, ni l'anti-rafale, ni
/// l'ordre du cycle : tout cela appartient au cubit et au [onResume] que lui
/// passe la racine. Ce widget ne connaît que le cycle de vie Flutter.
///
/// Transparent dans l'arbre : rend [child] tel quel.
class SyncResumeObserver extends StatefulWidget {
  /// Appelé à **chaque** passage à [AppLifecycleState.resumed], jamais sur les
  /// autres transitions. À la charge de l'appelant d'être idempotent et bon
  /// marché : sur Android, un simple aller-retour vers la liste des
  /// applications récentes suffit à le déclencher.
  final VoidCallback onResume;

  final Widget child;

  const SyncResumeObserver({
    super.key,
    required this.onResume,
    required this.child,
  });

  @override
  State<SyncResumeObserver> createState() => _SyncResumeObserverState();
}

class _SyncResumeObserverState extends State<SyncResumeObserver>
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
    // `resumed` SEUL. `inactive` encadre chaque transition (et, sur iOS, la
    // simple ouverture du centre de contrôle) : y réagir déclencherait un
    // cycle pour une notification balayée.
    if (state != AppLifecycleState.resumed) return;
    widget.onResume();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
