# Guide GitHub — Release step by step (clic par clic)

Ce document explique précisément quoi faire dans GitHub pour publier une release propre sur ce projet Flutter.

> Objectif : passer d’un code validé à une version **taggée**, **buildée** et **publiée** sans ambiguïté.

Voir aussi :
- `GITHUB_RELEASE_RUNBOOK.md` (mode opératoire interne écran par écran)
- `GITHUB_RELEASE_CHECKLIST.md` (checklist 1 page imprimable)

---

## 1) Vue d’ensemble du flux

### Flux recommandé
1. Fusionner le code prêt à livrer
2. Créer un **tag Git SemVer** `vX.Y.Z`
3. Lancer le workflow **Release Production**
4. Vérifier les artefacts générés
5. Publier la **GitHub Release** associée au tag
6. Envoyer les binaires vers les stores si nécessaire

### Convention de version
- **Prod** : `vX.Y.Z`
- Exemples : `v1.0.0`, `v1.0.1`, `v1.2.0`
- Un tag = une version officielle

---

## 2) Préparation initiale — à faire une seule fois

## 2.1 Créer les secrets GitHub Actions

### Chemin
- Ouvrir le dépôt GitHub
- Cliquer sur **Settings**
- Dans le menu de gauche, cliquer sur **Secrets and variables**
- Cliquer sur **Actions**
- Cliquer sur **New repository secret**

### Secrets à ajouter

#### Secrets d’environnement
- `DEV_API_BASE_URL`
- `STAGING_API_BASE_URL`
- `PROD_API_BASE_URL`

#### Secrets Android release
- `ANDROID_RELEASE_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

#### Optionnel plus tard pour iOS signing
- `MATCH_PASSWORD`
- `MATCH_GIT_BASIC_AUTHORIZATION`
- ou les secrets liés aux certificats / provisioning profiles

### Bon réflexe
Après chaque ajout :
- vérifier l’orthographe du nom
- vérifier qu’aucun espace n’a été ajouté
- ne pas publier la valeur du secret dans un commentaire ou un commit

---

## 2.2 Configurer l’environnement `prod`

### Chemin
- Ouvrir le dépôt GitHub
- Cliquer sur **Settings**
- Dans le menu de gauche, cliquer sur **Environments**
- Cliquer sur **New environment**
- Saisir `prod`
- Cliquer sur **Configure environment**

### Paramètres recommandés
- Activer **Required reviewers**
- Ajouter au moins une personne de validation
- Conserver cette étape comme garde-fou avant toute publication prod

### Optionnel
Créer aussi `staging` si vous voulez séparer les validations d’API et les déploiements intermédiaires.

---

## 2.3 Vérifier que les workflows existent

### Chemin
- Aller dans l’onglet **Code**
- Ouvrir le dossier `.github/workflows/`

### Fichiers attendus
- `build_android.yml`
- `build_ios.yml`
- `flutter_ci.yml`
- `release_prod.yml`

### Ce qu’ils font
- `flutter_ci.yml` : vérification continue
- `build_android.yml` : build manuel Android par environnement
- `build_ios.yml` : build manuel iOS par environnement
- `release_prod.yml` : release prod encadrée

---

## 3) Créer une release GitHub propre

Cette étape crée le **tag** officiel de la version.

## 3.1 Ouvrir la page Releases

### Chemin
- Ouvrir le dépôt GitHub
- Cliquer sur **Releases**
- Cliquer sur **Draft a new release**

## 3.2 Choisir le tag

Dans le champ de tag :
- taper `v1.2.3` par exemple
- si GitHub propose **Create new tag**, cliquer dessus

### Règle
- Le tag doit respecter le format `vX.Y.Z`
- Éviter les tags non semver comme `release-final` ou `prod-test`

## 3.3 Renseigner le titre

### Titre conseillé
- `v1.2.3`
- ou `Release 1.2.3`

### Bonnes pratiques
- Garder le titre court
- Rester cohérent d’une release à l’autre

## 3.4 Rédiger les notes de release

Dans la zone de description :
- lister les nouveautés
- lister les corrections
- mentionner les points de vigilance si besoin

Exemple :
- Ajout du module X
- Correction du flux de connexion
- Amélioration des performances sur l’écran Y

## 3.5 Publier la release

### Action
- Cliquer sur **Publish release**

### Résultat attendu
- Le tag `vX.Y.Z` existe dans le dépôt
- La release devient la référence officielle de cette version

---

## 4) Lancer la release production

C’est le workflow principal à utiliser pour une vraie mise en prod.

## 4.1 Ouvrir le workflow

### Chemin
- Cliquer sur l’onglet **Actions**
- Dans la liste des workflows, choisir **Release Production**
- Cliquer sur **Run workflow**

## 4.2 Remplir le formulaire

Vous verrez les champs suivants :

### `confirm_prod`
- Taper exactement : `prod`
- C’est la garde-fou anti-erreur

### `version_tag`
- Taper le tag exact de la release
- Exemple : `v1.2.3`

### `build_android`
- `true` si vous voulez générer l’AAB Android
- `false` si vous ne voulez pas le build Android

### `build_ios`
- `true` si vous voulez générer le build iOS
- `false` si vous ne voulez pas le build iOS

## 4.3 Lancer le workflow

### Action
- Cliquer sur **Run workflow**

### À surveiller
- si l’environnement `prod` exige une approbation, GitHub va mettre le job en attente
- un reviewer devra valider le déploiement

---

## 5) Suivre le déroulé dans GitHub Actions

## 5.1 Lire les jobs un par un

Dans l’exécution du workflow, vérifier l’ordre :
1. **Guard — Confirmation prod**
2. **Validate PROD env variables**
3. **Analyze & Test**
4. **Build Android prod** et/ou **Build iOS prod**
5. **Release summary**

## 5.2 Vérifier les résultats attendus

### Guard
- doit réussir immédiatement si `confirm_prod = prod`

### Validate env
- doit confirmer que l’URL prod est correcte

### Analyze & Test
- doit passer en vert
- si ça échoue, arrêter la release et corriger avant de continuer

### Build Android / iOS
- doit produire les binaires attendus
- doit injecter `--build-name` et `--build-number` correctement

### Release summary
- doit afficher un résumé lisible dans GitHub

---

## 6) Récupérer les artefacts générés

## 6.1 Ouvrir le run GitHub Actions

### Chemin
- Aller dans **Actions**
- Ouvrir le run terminé
- Descendre jusqu’à la section **Artifacts**

## 6.2 Téléchargement attendu

### Android
- artefact AAB Android
- nom généralement proche de `android-prod-aab-<sha>`

### iOS
- artefact iOS build
- nom généralement proche de `ios-build-prod-<sha>`

## 6.3 Que faire ensuite

### Android
- transférer l’AAB vers la Google Play Console si le process de publication l’exige

### iOS
- utiliser le workflow iOS / signing prévu lorsque l’export IPA sera prêt

---

## 7) Déclencher un build manuel hors release prod

Si vous voulez juste tester un build par environnement :

## 7.1 Build Android

### Chemin
- onglet **Actions**
- workflow **Build Android**
- cliquer **Run workflow**

### Champs
- `environment` : `dev`, `staging` ou `prod`
- `build_type` : `apk` ou `appbundle`
- `version_tag` : obligatoire pour `prod`

### Recommandation
- pour dev/staging, utiliser les builds de validation
- pour prod, préférer `Release Production`

## 7.2 Build iOS

### Chemin
- onglet **Actions**
- workflow **Build iOS**
- cliquer **Run workflow**

### Champs
- `environment` : `dev`, `staging` ou `prod`
- `export_method` : `development`, `ad-hoc` ou `app-store`
- `version_tag` : obligatoire pour `prod`

---

## 8) Procédure complète “clic par clic” pour une vraie release

### Étape 1
- Aller dans **Code**
- Vérifier que la branche à publier est prête

### Étape 2
- Aller dans **Releases**
- Cliquer **Draft a new release**

### Étape 3
- Saisir le tag : `vX.Y.Z`
- Saisir un titre clair
- Renseigner les notes de release
- Cliquer **Publish release**

### Étape 4
- Aller dans **Actions**
- Ouvrir **Release Production**
- Cliquer **Run workflow**

### Étape 5
- Remplir :
  - `confirm_prod = prod`
  - `version_tag = vX.Y.Z`
  - `build_android = true/false`
  - `build_ios = true/false`

### Étape 6
- Cliquer **Run workflow**

### Étape 7
- Si GitHub demande une approbation `prod`
  - ouvrir la demande
  - cliquer **Review deployments**
  - cliquer **Approve and deploy**

### Étape 8
- Suivre les logs jusqu’à la fin
- Télécharger les artefacts si nécessaire

---

## 9) Check-list avant de cliquer sur “Run workflow”

- [ ] Les secrets GitHub Actions existent
- [ ] L’environnement `prod` est configuré
- [ ] Le tag `vX.Y.Z` est créé
- [ ] La release GitHub est publiée
- [ ] Le code est validé par CI
- [ ] `confirm_prod` vaut bien `prod`
- [ ] Le bon `version_tag` est saisi
- [ ] Le bon build est sélectionné (`Android`, `iOS` ou les deux)

---

## 10) Erreurs fréquentes et quoi faire

### Erreur : `version_tag` manquant
**Cause :** build prod lancé sans tag
**Solution :** relancer en saisissant `vX.Y.Z`

### Erreur : tag invalide
**Cause :** tag non SemVer ou mal saisi
**Solution :** utiliser un format comme `v1.2.3`

### Erreur : secret manquant
**Cause :** secret GitHub Actions absent ou mal nommé
**Solution :** retourner dans **Settings → Secrets and variables → Actions**

### Erreur : environnement prod bloqué
**Cause :** approbation requise non encore donnée
**Solution :** aller dans l’environnement concerné et approuver le déploiement

### Erreur : workflow rouge sur les tests
**Cause :** régression fonctionnelle ou de build
**Solution :** corriger le code avant toute publication

---

## 11) Règle d’or

- **Jamais de prod sans tag `vX.Y.Z`**
- **Jamais de release prod sans approbation si l’environnement l’exige**
- **Jamais de nouveau build prod sur un tag déjà publié**

---

## 12) Résumé ultra-court

### Pour publier une version
1. Créer le tag `vX.Y.Z`
2. Publier la release GitHub
3. Lancer **Release Production**
4. Saisir `confirm_prod = prod`
5. Saisir `version_tag = vX.Y.Z`
6. Approuver si demandé
7. Télécharger les artefacts

---

## 13) Note interne

Ce guide est pensé pour être utilisé par une personne qui n’a pas le contexte complet du projet.
Il privilégie le **clic par clic** et la **sécurité de release**.
