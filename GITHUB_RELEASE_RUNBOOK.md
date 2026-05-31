# Runbook interne — Release GitHub (écran par écran)

Ce runbook est une version opérationnelle courte pour exécuter une release sans ambiguïté.

---

## 0) Pré-requis (avant toute release)

- Secrets configurés dans GitHub Actions
- Environment `prod` configuré avec approbation
- Branche de release mergee et CI verte
- Version cible décidée (`vX.Y.Z`)

---

## 1) Créer la version (tag) dans GitHub

## Écran: `Releases`
1. Ouvrir le repo GitHub
2. Cliquer `Releases`
3. Cliquer `Draft a new release`

## Écran: `Draft a new release`
1. Dans `Choose a tag`, saisir `vX.Y.Z` (ex: `v1.3.0`)
2. Si proposé, cliquer `Create new tag`
3. Titre: `vX.Y.Z`
4. Remplir les notes (nouveautés/correctifs)
5. Cliquer `Publish release`

Résultat attendu:
- Le tag `vX.Y.Z` existe
- Une release GitHub visible est publiée

---

## 2) Lancer le workflow de prod

## Écran: `Actions`
1. Ouvrir `Release Production`
2. Cliquer `Run workflow`

## Formulaire `Run workflow`
- `confirm_prod`: `prod`
- `version_tag`: `vX.Y.Z` (exactement le tag créé)
- `build_android`: `true`/`false`
- `build_ios`: `true`/`false`

3. Cliquer `Run workflow`

---

## 3) Approuver le déploiement prod (si requis)

## Écran: `Actions` (run en attente)
1. Ouvrir le run en attente
2. Cliquer `Review deployments`
3. Choisir l’environment `prod`
4. Cliquer `Approve and deploy`

---

## 4) Vérifier les jobs et les logs

Ordre attendu des jobs:
1. `Guard — Confirmation prod`
2. `Validate PROD env variables`
3. `Analyze & Test (release gate)`
4. `Build Android prod (App Bundle)` (si activé)
5. `Build iOS prod (IPA)` (si activé)
6. `Release summary`

Si un job échoue:
- Ne pas republier avec le même tag
- Corriger, puis relancer avec un nouveau tag

---

## 5) Récupérer les artefacts

## Écran: run GitHub Actions terminé
1. Descendre à `Artifacts`
2. Télécharger:
   - Android: `android-prod-aab-<sha>`
   - iOS: artefact iOS correspondant

---

## 6) Contrôles de sortie

- Le run est vert
- Les artefacts sont téléchargeables
- La release GitHub `vX.Y.Z` est publiée
- Les informations de version sont cohérentes avec le tag

---

## 7) Erreurs fréquentes

- `version_tag` vide ou invalide
  - Attendu: `vX.Y.Z`
- Secrets manquants
  - Vérifier `Settings > Secrets and variables > Actions`
- Déploiement bloqué
  - Vérifier l’approbation de l’environment `prod`

---

## 8) Règles d’exploitation

- Un tag stable = une release officielle
- Pas de redéploiement prod sur un tag déjà utilisé
- Toute correction post-release doit utiliser un nouveau tag
