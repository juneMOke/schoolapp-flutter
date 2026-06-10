# CLAUDE.md — module `bootstrap`

Spécifique au module de chargement initial. Lire le `CLAUDE.md` racine et `AGENTS.md` pour les règles globales.

---

## Périmètre du module

Charger et mettre en cache les données fondamentales nécessaires au reste de l'app **après authentification** :
- Année scolaire courante (et précédente)
- Classes, niveaux scolaires, groupes de niveaux
- Tarifs
- Bundle complet retourné par l'API en un seul appel

Ce module **bloque la navigation** tant que le chargement initial n'est pas terminé. C'est sa caractéristique fondamentale.

## Structure interne particulière

Trois BLoCs distincts :

| BLoC | Rôle |
|---|---|
| `BootstrapBloc` | Chargement remote + local du bootstrap (current + previous year) |
| `BootstrapCurrentYearBloc` | Lecture du cache local pour l'année courante |
| `BootstrapPreviousYearBloc` | Lecture du cache local pour l'année précédente |
| `BootstrapContextBloc` | Sélection du contexte actif (current vs previous) côté UI |

→ Le `BootstrapBloc` est le **point d'orchestration**. Les trois autres sont des lecteurs spécialisés.

Deux repositories séparés :

- `BootstrapRemoteRepository` — appel API
- `BootstrapLocalRepository` — Hive

## Flow de chargement

```
1. main.dart démarre
   → BootstrapBloc.add(BootstrapLocalRequested(bootstrapPayloadKey))
   → tente de lire le cache Hive immédiatement (rapide, offline-first)

2. AuthBloc émet authenticated
   → main.dart écoute, déclenche :
       BootstrapRemoteCurrentYearRequested
       BootstrapRemotePreviousYearRequested
   → l'API renvoie le bundle, on sauve dans Hive, on émet success

3. AuthBloc émet unauthenticated
   → main.dart écoute, déclenche BootstrapResetRequested
   → state remis à initial
```

## `blocksNavigation` — règle critique

Le router (`RouterNotifier` dans `app_router.dart`) consulte
`bootstrapBloc.state.blocksNavigation` avant d'autoriser les routes app.

**Modèle offline-first (depuis la refonte splash)** : la navigation est pilotée
par la **disponibilité des données** (`hasData = bootstrap != null`), pas par
« le réseau a-t-il répondu ». Dès qu'un cache local est chargé, on entre dans
l'app et le réseau rafraîchit **en tâche de fond**.

```dart
bool get hasData => bootstrap != null;

// Bloque UNIQUEMENT tant qu'on n'a aucune donnée ET qu'on n'est pas déjà en
// échec distant (sinon c'est l'ErrorView qui prend le relais).
bool get blocksNavigation =>
    !hasData &&
    !(status == BootstrapLoadStatus.failure && operation.blocksNavigation);

// Seul cas réellement bloquant : aucune donnée + échec distant → ErrorView.
bool get hasBlockingFailure =>
    !hasData &&
    status == BootstrapLoadStatus.failure &&
    operation.blocksNavigation;

// On affiche du cache car le refresh distant a échoué → bandeau hors-ligne.
bool get isStale =>
    source == BootstrapSource.local && status == BootstrapLoadStatus.failure;

// operation.blocksNavigation est true UNIQUEMENT pour :
//   - BootstrapOperation.remoteCurrentYear
//   - BootstrapOperation.remotePreviousYear
```

Décision d'entrée résumée (gérée par le redirect du router + `SplashPage`) :

| JWT (local) | Cache | Comportement |
|---|---|---|
| absent/expiré | — | `/login` (zéro réseau) |
| valide | présent | `/home` direct + refresh en fond (bandeau hors-ligne si refresh KO) |
| valide | absent | splash (loading) → `/home`, ou ErrorView+Réessayer si échec |

**Session expirée (401/403)** : un échec distant d'auth lève
`state.sessionExpired = true`. `main.dart` écoute le `BootstrapBloc` et déclenche
alors `AuthLogoutRequested` (couplage bootstrap→auth en sens unique, via main).

→ Un `BootstrapLocalRequested` en cours ne bloque **pas** la navigation (offline-first).

→ Si tu ajoutes une nouvelle `BootstrapOperation`, **décide explicitement** si elle doit bloquer la navigation et mets à jour `BootstrapOperationX.blocksNavigation`.

## Clés Hive utilisées

Définies dans `AppConstants` :

- `bootstrapPayloadKey` — bundle de l'année courante
- `bootstrapPreviousYearPayloadKey` — bundle de l'année précédente

→ Ne **jamais** écrire/lire ces clés depuis l'extérieur du module. Passer par les UseCases (`SaveLocalBootstrapUseCase`, `GetLocalBootstrapUseCase`).

## Migrations Hive

Géré par `BootstrapLocalMigrationService` (dans `data/services/`).
À lancer dans `configureDependencies()` (`injection.dart`) **avant** toute ouverture des Hive boxes utilisateur.

→ Toute modification du schéma d'une entité bootstrap (`Bootstrap`, `BootstrapAcademicYear`, etc.) implique :
1. Bumper la version dans `BootstrapLocalMigrationService`
2. Écrire la migration (lire ancien format, sauver nouveau)
3. Tester avec un cache existant

## Pièges fréquents

1. **Ne pas déclencher de remote bootstrap depuis un widget** — uniquement depuis `main.dart` en réaction à `AuthBloc`. Sinon : double-fetch, race conditions, navigation qui flicker.
2. **`BootstrapResetRequested` ne clear pas le cache Hive** — il remet juste le state à initial. Pour vider Hive : `BootstrapClearLocalRequested(key)`. C'est volontaire : on garde le cache pour le prochain login.
3. **`BootstrapState.operation` est privé (`_operation`)** avec un getter qui renvoie `BootstrapOperation.none` si null — ne pas accéder à `_operation` directement.
4. **`copyWith` utilise le sentinel `_undefined`** pour distinguer "pas passé" vs "passé à null" (cf. AGENTS.md §8). Respecter ce pattern si on étend le state.
5. **Toujours émettre `operation`** dans les transitions — l'opération courante est utilisée par `blocksNavigation` ET sert au debug.
6. **Toute extension du flow** (ex. ajouter une fetch supplémentaire) → mettre à jour les listeners de `main.dart` et la logique de `RouterNotifier`. Ces trois fichiers sont fortement couplés.

## Couplage à vérifier après tout changement

| Fichier | Pourquoi |
|---|---|
| `lib/main.dart` | Listener `AuthBloc → BootstrapBloc` |
| `lib/router/app_router.dart` | `RouterNotifier` lit `state.blocksNavigation` |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Transitions de status qui déclenchent les fetch |
