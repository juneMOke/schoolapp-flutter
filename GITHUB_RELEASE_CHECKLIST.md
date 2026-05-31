# Checklist release GitHub (1 page)

Imprimable / copiable en ticket release.

---

## A. Préparation

- [ ] Code merge sur la branche cible
- [ ] `flutter_ci.yml` vert
- [ ] Secrets GitHub présents (API + signing)
- [ ] Environment `prod` actif avec approbation
- [ ] Version décidée: `vX.Y.Z`

---

## B. Création de release GitHub

- [ ] `Releases` > `Draft a new release`
- [ ] Tag saisi: `vX.Y.Z`
- [ ] Titre saisi: `vX.Y.Z`
- [ ] Notes de release rédigées
- [ ] `Publish release` cliqué

---

## C. Exécution du workflow

- [ ] `Actions` > `Release Production`
- [ ] `Run workflow` ouvert
- [ ] `confirm_prod = prod`
- [ ] `version_tag = vX.Y.Z`
- [ ] `build_android` défini
- [ ] `build_ios` défini
- [ ] `Run workflow` lancé

---

## D. Approbation (si demandée)

- [ ] `Review deployments` ouvert
- [ ] Environment `prod` sélectionné
- [ ] `Approve and deploy` validé

---

## E. Vérification des jobs

- [ ] Guard OK
- [ ] Validate env OK
- [ ] Analyze & Test OK
- [ ] Build Android OK (si activé)
- [ ] Build iOS OK (si activé)
- [ ] Release summary OK

---

## F. Artefacts et publication

- [ ] Artefacts téléchargés depuis le run
- [ ] Android AAB récupéré (si activé)
- [ ] iOS build/IPA récupéré (si activé)
- [ ] Release `vX.Y.Z` visible dans GitHub

---

## G. Règles de sécurité

- [ ] Aucun secret exposé dans logs/commentaires
- [ ] Pas de re-run prod avec le même tag
- [ ] En cas de correctif: nouveau tag `vX.Y.Z+1` (ou bump adapté)
