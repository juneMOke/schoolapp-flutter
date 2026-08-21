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

  /// Appelé quand l'application quitte réellement l'écran : `paused`,
  /// `hidden`, `detached`.
  ///
  /// ⚠️ **`inactive` n'en fait PAS partie, et n'appelle rien du tout.** C'est
  /// un état de recouvrement transitoire — volet de notifications, boîte de
  /// dialogue de permission, feuille de partage, sélecteur de fichiers,
  /// changement de focus en écran partagé — pendant lequel l'application est
  /// toujours là. Le traiter comme un retrait coupait le battement puis le
  /// recréait au retour, compte à rebours remis à zéro : un utilisateur qui
  /// franchit cette frontière plus souvent que la période ne recevait **plus
  /// aucun** tic, et le drapeau d'armement affichait « actif » pendant ce
  /// temps. Sur la cible Android de ce projet, ces états sont fréquents.
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
    // ⚠️ Un observateur fraîchement ajouté ne reçoit AUCUN état : le binding ne
    // notifie que des *transitions*. Le consommateur suppose donc « premier
    // plan » au départ, et sur une application démarrée hors de l'écran cette
    // supposition ne serait jamais corrigée.
    //
    // Rien n'est semé ici pour autant. Sur la cible de ce projet — une tablette
    // Android dont le manifeste ne déclare qu'une activité LAUNCHER, ni service
    // ni receiver — le seul consommateur (le battement) ne s'arme qu'à
    // l'ouverture de session, laquelle exige un écran. Le cas ne se pose que
    // sur bureau ou web, hors périmètre. Et la lecture de
    // `WidgetsBinding.instance.lifecycleState` en `initState` n'est pas
    // observable sous `testWidgets` : le poser en aveugle vaut moins qu'une
    // supposition assumée et écrite. Cf. `REVUE_CODE_BACKLOG.md`.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _dispatch(state);

  void _dispatch(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.onResume();
      case AppLifecycleState.inactive:
        // Délibérément muet — cf. la docstring de [SyncLifecycleObserver.onPause].
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        widget.onPause();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
