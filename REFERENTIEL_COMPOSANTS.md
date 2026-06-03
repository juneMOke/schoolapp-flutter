# Referentiel de composants UI

Ce document centralise les composants UI partageables du projet.

Objectifs:
- documenter le role de chaque composant
- expliciter les slots attendus par la page appelante
- poser un contrat de reactvite clair (base sur le conteneur, pas le viewport)
- faciliter la reutilisation et limiter les variantes ad-hoc

---

## 1) BiToneSectionCard

- **Fichier**: `lib/core/widgets/bi_tone_section_card.dart`
- **Type Flutter**: `StatelessWidget`
- **Statut**: composant de reference (shell de section)

### Description

Coquille de carte reutilisable pour sections de recherche, etapes de parcours et blocs de formulaire.

Le composant gere:
- la surface de carte (fond, radius, bordure, ombre)
- un en-tete optionnel bi-ton (degrade bleu pale -> creme)
- un mode en-tete structure (icone + titre + sous-titre)
- un mode en-tete libre via slot `header`

Le contenu metier est toujours fourni par la page via `child`.

### Zones caracteristiques

- **Carte**
  - background: `AppColors.surfaceRaised` (visuel cible blanc)
  - radius: `AppRadius.brCard` (20)
  - border: `1px AppColors.border`
  - shadow: `AppElevation.shadowCard` (optionnelle via `showShadow`)

- **En-tete bi-ton**
  - fond: `LinearGradient(#F5F8FB -> #FBF6EF)`
  - bordure basse: `1px AppColors.border`
  - radius haut: `BorderRadius.vertical(top: AppRadius.card)`
  - padding par defaut: horizontal `AppSpacing.xl - 2`, vertical `AppSpacing.lg + 2`

- **Leading structure**
  - rail accent vertical
  - pastille icone 36x36
  - radius pastille 10
  - icone 18
  - ombre teintee par `accentColor`

### Slots (fournis par la page)

- `child` *(required)*
  - corps libre (grille de filtres, formulaire, actions, etc.)

- `header` *(optional)*
  - en-tete custom complet
  - prioritaire sur le mode structure

- `title` / `subtitle` / `icon` *(optional)*
  - utilise le mode en-tete structure si `header` est absent

- `accentColor` *(optional)*
  - couleur d'accent pour rail/pastille (defaut `AppColors.bleuArdoise`)

- `bodyPadding` *(optional)*
  - padding du corps (defaut 22dp)

- `headerPadding` *(optional)*
  - padding de l'en-tete

- `showShadow` *(optional)*
  - active/desactive l'ombre de carte

### Contrat de reactvite (conteneur)

- Le composant ne fixe pas de largeur dure: `width: double.infinity`.
- Il remplit la largeur du parent et s'adapte aux contraintes du conteneur.
- Le header structure bascule selon la largeur disponible:
  - **large**: layout horizontal (leading + texte)
  - **etroit**: layout empile (leading puis texte)
- Le slot `child` garde sa propre logique responsive (responsabilite de la page/widget metier).

### Contrat d'utilisation Flutter

- Prioriser ce composant pour toute carte de section avec en-tete decoratif.
- Preferer `title/subtitle/icon` pour les cas standards.
- Utiliser `header` uniquement si une structure speciale est necessaire.
- Ne pas dupliquer la decoration de carte dans les features quand ce shell convient.

### Accessibilite (WCAG 2.1 AA)

- **Titre**
  - si `title` est fourni, il est expose comme un vrai heading pour la navigation lecteur d'ecran
  - mapping Flutter: `Semantics(header: true)` applique sur le texte du titre
  - references: `1.3.1` (Info and Relationships), `2.4.6` (Headings and Labels)

- **Icone/Pastille decorative**
  - le bloc leading (rail + pastille + icone) est purement decoratif dans le mode structure
  - il est exclu de l'arbre semantique
  - mapping Flutter: `ExcludeSemantics`
  - reference: `1.3.1`

- **Header custom (`header`)**
  - si la page fournit un header custom, la responsabilite a11y du heading est cote appelant
  - le composant priorise `header` et n'affiche pas le header structure en doublon

### Exemples d'usages actuels

- `lib/features/enrollment/presentation/widgets/search_form/search_form_responsive_view.dart`
- `lib/features/enrollment/presentation/widgets/re_registration_search_invitation_card.dart`
- `lib/features/classes/presentation/widgets/classes_list_search_form.dart`

### Tests associes

- `test/core/widgets/bi_tone_section_card_test.dart`
  - header horizontal quand conteneur large
  - header empile quand conteneur etroit
  - priorite du slot `header` sur le header structure

---

## 2) EteeloButton

- **Fichier**: `lib/core/widgets/eteelo_button.dart`
- **Type Flutter**: `StatefulWidget`
- **Statut**: composant de reference (primitive bouton)

### Description

Bouton design-system unifie pour les actions de formulaire et CTA.

Le composant gere:
- 4 variantes semantiques: `primary`, `secondary`, `ghost`, `danger`
- 2 tailles: `compact` (actions inline) et `regular` (CTA page/wizard)
- les etats visuels repos / hover / pressed / focus / disabled / loading
- un focus ring coherent avec les inputs Eteelo
- une base semantique accessibilite (`Semantics(button: true, ...)`)

### Zones caracteristiques

- **Variantes**
  - `primary`: fond `AppColors.terreCuite`, texte `AppColors.blancCasse`
  - `secondary`: transparent, bordure `1.5px AppColors.bleuArdoise`, texte `AppColors.bleuArdoise`
  - `ghost`: transparent, sans bordure, texte `AppColors.bleuArdoise`
  - `danger`: fond `AppColors.error`, texte `AppColors.blancCasse`

- **Tailles**
  - `compact` (sm): min height 40, min width 112
  - `regular` (md): min height 48, `fullWidth` configurable
  - rayon: pilule (`StadiumBorder` / radius 999)

- **Espacement et typographie**
  - padding horizontal: `md=22`, `sm=16`, `ghost=8`
  - gap icone/label: `8`
  - label: `label-large`, `500`, `14/1.2`
  - taille icone/spinner: `md=18`, `sm=16`

- **Interaction**
  - hover / pressed via `overlayColor`
  - focus ring via `BoxShadow(AppColors.stateFocus, spreadRadius: 2)`
  - `isLoading: true` conserve l'apparence active (no-op callback) avec spinner

### Slots / props (fournis par la page)

- `label` *(required)*
- `onPressed` *(required nullable, pour disabled)*
- `icon` *(optional)*
- `isLoading` *(optional)*
- `size` *(optional: `EteeloButtonSize.compact|regular`)*
- `fullWidth` *(optional, surtout utile avec `size: regular`)*
- `tooltip` *(optional)*

### Contrat de reactvite (conteneur)

- `compact`: largeur naturelle du contenu, avec min-width 112
- `regular`: pleine largeur par defaut (`fullWidth: true`), ou largeur naturelle si `fullWidth: false`
- aucune contrainte de largeur globale forcee en dehors du comportement de taille

### Accessibilite (WCAG 2.1 AA)

- role bouton explicite via `Semantics`
- etat enabled/disabled expose semantiquement
- focus visible (ring dedie), non base uniquement sur la couleur
- spinner visible en loading avec etat semantique disabled

### Contrat d'utilisation Flutter

- utiliser cette primitive pour tout nouveau bouton d'action metier
- choisir `size: compact` pour actions de filtres/listings, `size: regular` pour CTA principaux
- preferer `ghost` pour actions secondaires legeres (ex: effacer/reinitialiser)
- reserver `danger` aux actions destructives

### Wrappers de compatibilite (deprecie)

- `lib/core/components/buttons/primary_button.dart`
  - wrapper vers `EteeloButton.primary` / `EteeloButton.danger`
  - **deprecie**
- `lib/core/components/buttons/secondary_button.dart`
  - wrapper vers `EteeloButton.secondary`
  - **deprecie**
- `lib/core/widgets/eteelo_validation_button.dart`
  - wrapper vers `EteeloButton.primary(size: EteeloButtonSize.regular)`
  - **deprecie**

### Exemples d'usages actuels

- `lib/features/enrollment/presentation/widgets/search_form.dart`
- `lib/features/enrollment/presentation/widgets/re_registration_search_form.dart`
- `lib/features/classes/presentation/widgets/classes_list_search_actions.dart`
- `lib/features/finance/presentation/widgets/facturation_search_form.dart`
- `lib/features/auth/presentation/widgets/login_form.dart`

### Tests associes

- `test/core/widgets/eteelo_button_test.dart`
  - variantes primary / secondary / ghost / danger
  - etats loading / disabled / focus
  - tailles regular + comportement `fullWidth`

---

## 3) EteeloTextInput

- **Fichier**: `lib/core/widgets/eteelo_text_input.dart`
- **Type Flutter**: `StatefulWidget`
- **Statut**: composant de reference (primitive input texte)

### Description

Champ texte editorial de reference pour les formulaires Eteelo.

Le composant gere:
- un label externe en serif `Lora`
- un champ texte simple et fluide, pilote par `controller`
- les etats visuels repos / focus / erreur / readonly / disabled
- la compensation de padding au focus pour eviter tout saut de layout
- une base d'accessibilite WCAG 2.1 AA

### Zones caracteristiques

- **Label**
  - typo: `AppTypography.labelFormLarge`
  - style cible: Lora 600 13 / 1.3
  - couleur: `AppColors.textPrimary`
  - gap au-dessus du champ: 6dp
  - `required: true` -> suffixe `*`

- **Champ**
  - hauteur cible: 46dp en mono-ligne
  - radius: `AppRadius.brSm`
  - texte saisi: `AppTypography.bodyMedium`, `AppColors.textPrimary`
  - placeholder: `AppColors.textMuted`
  - fond repos: `AppColors.surface`
  - fond readonly: `AppColors.surfaceAlt`

- **Bordure**
  - repos: `1px AppColors.border`
  - focus: `2px AppColors.bleuArdoise`
  - focus ring: `AppColors.stateFocus`
  - padding horizontal compense: `12 -> 11`

### Slots / props (fournis par la page)

- `controller` *(required)*
  - source de verite de la valeur saisie

- `label` *(required)*
  - libelle visible au-dessus du champ

- `placeholder` *(optional)*
  - aide contextuelle secondaire

- `keyboardType` *(optional)*
  - enum `EteeloTextInputType`: `text`, `phone`, `email`, `number`, `multiline`

- `readOnly` *(optional)*
  - champ non editable, fond `surfaceAlt`

- `required` *(optional)*
  - ajoute `*` et enrichit la semantique d'obligation

- `enabled` *(optional)*
  - active / desactive le champ

- `errorText` *(optional)*
  - message d'erreur affiche sous le champ

- `validator` *(optional)*
  - validation `FormField` Flutter

- `onChanged`, `onSubmitted`, `onTap` *(optional)*
  - callbacks d'interaction

- `focusNode`, `textInputAction`, `autofillHints`, `inputFormatters`, `minLines`, `maxLines` *(optional)*
  - options Flutter avancees laissees a la page

### Contrat de reactvite (conteneur)

- aucune largeur fixe imposee par le composant
- largeur pilotee par le parent
- label toujours au-dessus du champ
- usage recommande a partir d'environ 180px de large, sans `minWidth` dur embarque
- le composant reste mono-colonne par construction; la grille appartient a la page

### Accessibilite (WCAG 2.1 AA)

- **Libelle**
  - le champ expose `label` comme libelle semantique principal
  - `required: true` ajoute une indication semantique d'obligation
  - references: `1.3.1`, `3.3.2`, `4.1.2`

- **Erreur**
  - `errorText` est rendu visuellement sous le champ
  - le message est integre au hint semantique du champ
  - references: `3.3.1`, `4.1.2`

- **Placeholder**
  - pure aide secondaire, jamais substitut du label
  - reference: `1.3.1`

- **Focus**
  - signal par bordure 2px + focus ring
  - pas un signal base uniquement sur la couleur
  - references: `2.4.7`, `1.4.11`

### Contrat d'utilisation Flutter

- utiliser `controller` comme source de verite
- laisser la page piloter layout, largeur et validation metier
- reserver les cas specialises (email, password, etc.) a des wrappers dedies
- ne pas transformer cette primitive en champ generique a prefix/suffix complexes sans nouveau besoin valide

### Exemples d'usages actuels

- `lib/features/enrollment/presentation/widgets/search_form.dart`
- wrappers texte metier a venir (email/password)

### Tests associes

- `test/core/widgets/eteelo_text_input_test.dart`
  - label + etoile pour champ requis
  - compensation visuelle au focus
  - fond readonly
  - message d'erreur
  - semantique label / required / erreur

---

## 4) EteeloDateInput

- **Fichier**: `lib/core/widgets/eteelo_date_input.dart`
- **Type Flutter**: `StatefulWidget`
- **Statut**: composant de reference (primitive input date)

### Description

Champ date de reference avec ouverture native du calendrier (`showDatePicker`).

Le composant gere:
- un label externe coherent avec `EteeloTextInput`
- un affichage de date formatee `dd/MM/yyyy`
- les etats visuels repos / focus / erreur / disabled
- l'integration formulaire via `FormField<DateTime>`
- les options du picker natif (`locale`, `helpText`, `cancelText`, `confirmText`)

### Zones caracteristiques

- **Label**
  - typo: `AppTypography.labelFormLarge`
  - `required: true` -> suffixe `*`

- **Champ**
  - hauteur cible: 46dp
  - fond repos: `AppColors.surface`
  - fond disabled: `AppColors.surfaceAlt`
  - icone calendrier inline a droite
  - valeur affichee: `dd/MM/yyyy`

- **Bordure**
  - repos: `1px AppColors.border`
  - focus (picker ouvert): `2px AppColors.bleuArdoise`
  - focus ring: `AppColors.stateFocus`
  - padding horizontal compense: `12 -> 11`

### Slots / props (fournis par la page)

- `label` *(required)*
- `value` *(optional, DateTime?)*
- `onChanged` *(optional, ValueChanged<DateTime?>)*
- `placeholder`, `required`, `enabled`, `errorText`, `validator` *(optional)*
- `firstDate`, `lastDate`, `initialPickerDate` *(optional)*
- `locale`, `helpText`, `cancelText`, `confirmText` *(optional)*

### Contrat de reactvite (conteneur)

- aucune largeur fixe imposee
- label toujours au-dessus du champ
- composant mono-colonne; la grille reste a la charge de la page

### Accessibilite (WCAG 2.1 AA)

- label semantique explicite, enrichi si `required`
- message d'erreur visible et expose via hint semantique
- focus explicite (bordure + focus ring), pas uniquement couleur

### Contrat d'utilisation Flutter

- utiliser pour toute date avec selection calendrier
- ne pas forcer une saisie clavier libre pour date de naissance
- conserver le format ISO (`yyyy-MM-dd`) dans la couche metier/API, pas dans le widget

### Exemples d'usages actuels

- `lib/features/enrollment/presentation/widgets/search_form.dart`
- `lib/features/enrollment/presentation/widgets/personal_info/personal_info_step_body.dart`

### Tests associes

- tests widget dedies a ajouter (ouvrir picker, rendu valeur, etat erreur)

---

## Template pour prochains composants

Copier/coller cette section pour toute nouvelle entree:

```md
## X) ComponentName

- **Fichier**: `lib/...`
- **Type Flutter**: `StatelessWidget|StatefulWidget|...`
- **Statut**: draft|stable|deprecated

### Description
...

### Zones caracteristiques
...

### Slots (fournis par la page)
...

### Contrat de reactvite (conteneur)
...

### Contrat d'utilisation Flutter
...

### Exemples d'usages actuels
...

### Tests associes
...
```