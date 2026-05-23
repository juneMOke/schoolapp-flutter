# 📖 Guide Complet - Utilisation des Templates

Bienvenue ! Ce guide vous explique comment utiliser les templates pour implémenter de nouvelles features.

---

## 📂 Fichiers Disponibles

```
FEATURE_TEMPLATE.md  → Template complet et détaillé (recommandé pour débuter)
QUICK_TEMPLATE.md    → Template rapide et formulaire (pour les iterations)
USAGE_GUIDE.md       → Ce fichier (instructions)
```

---

## 🎯 3 ÉTAPES SIMPLES

### Étape 1: Choisir le Template

| Template | Quand l'utiliser | Temps |
|----------|------------------|-------|
| **FEATURE_TEMPLATE** | Première fois, feature complexe | 5-10 min |
| **QUICK_TEMPLATE** | Iterations, modules similaires | 2-5 min |

### Étape 2: Compléter les Sections

Lisez attentivement chaque section et remplissez avec vos informations.

### Étape 3: Envoyer

Copiez-collez le template complété dans une demande à ChatGPT.

---

## 📋 SECTIONS DU TEMPLATE EXPLIQUÉES

### 1️⃣ INFORMATIONS GÉNÉRALES

```
Nom du module: Parent, Guardian, Teacher, etc.
Localisation: Toujours /lib/features/[nom]/
Description: 1-2 lignes sur le rôle du module
```

**Exemple:**
```
Nom du module: Guardian
Description: Gestion des tuteurs légaux des élèves
```

---

### 2️⃣ ENTITY & DATA MODEL

L'entity est la classe qui représente l'objet métier.

```
Entity name: [NomAuSingulier]Summary ou [NomAuSingulier]
Champs: Énumérez TOUS les champs avec leurs types
```

**Règles:**
- `String?` = nullable
- `String` = obligatoire
- Énums si catégories (ex: RelationshipType)
- Utilisez les types corrects (int, double, DateTime, etc.)

**Exemple:**
```
Entity: GuardianSummary
Champs:
- id: String (identifiant unique)
- firstName: String (prénom)
- lastName: String (nom)
- email: String (email)
- phoneNumber: String (téléphone)
- relationshipType: String (type de relation: FATHER, MOTHER, GUARDIAN)
- identificationNumber: String (numéro d'ID)
```

---

### 3️⃣ API ENDPOINTS

**Obligatoire:** Connaitre vos endpoints API.

```
Base URL: /api/v1/[resource] (ex: /api/v1/guardians)

Opérations possibles:
- POST /api/v1/guardians (créer)
- PUT /api/v1/guardians/{id} (mettre à jour)
- GET /api/v1/guardians/{id} (récupérer 1)
- DELETE /api/v1/guardians/{id} (supprimer)
- GET /api/v1/guardians (lister tous)
```

**À définir:**
- Quels champs en entrée (requête)
- Quels champs en sortie (réponse)
- Quels codes d'erreur retourner

**Exemple REQUEST:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phoneNumber": "+243981000023",
  "relationshipType": "FATHER"
}
```

**Exemple RESPONSE:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phoneNumber": "+243981000023",
  "relationshipType": "FATHER",
  "identificationNumber": "ID-12345678"
}
```

---

### 4️⃣ CAS D'USAGE (USE CASES)

Un use case = **une action métier**.

**Types courants:**
- **Create** → Créer une nouvelle ressource
- **Update** → Mettre à jour une ressource existante
- **Get** → Récupérer une ressource par ID
- **Delete** → Supprimer une ressource
- **List** → Lister toutes les ressources (avec pagination)

**Format:**
```
Use Case: [Action][Module]
- Entrée: [paramètres]
- Sortie: [résultat]
- Erreurs: [erreurs possibles]
```

**Exemple:**
```
Use Case: UpdateGuardian
- Entrée: guardianId, firstName, lastName, email, phoneNumber, relationshipType
- Sortie: Guardian entity
- Erreurs: NotFound, Unauthorized, ValidationFailure
```

---

### 5️⃣ BLOC EVENTS & STATES

Le BLoC gère l'état de la UI.

**Events** = Actions que l'utilisateur effectue
**States** = États de l'application

**Format d'un Event:**
```
[Module][Action]Requested
- Parameters: [liste des paramètres passés]
```

**Exemple:**
```
GuardianUpdateRequested
- Parameters: id, firstName, lastName, email, phoneNumber, relationshipType

GuardianDeleteRequested
- Parameters: id

GuardianListRequested
- Parameters: page, size, filters (optionnel)
```

**States à prévoir:**
- `initial` → Au démarrage
- `loading` → En attente de l'API
- `success` → Opération réussie
- `failure` → Erreur lors de l'opération

---

### 6️⃣ GESTION DES ERREURS

**Les 6 types d'erreurs principaux:**

| Code HTTP | Type Failure | Signification |
|-----------|--------------|---------------|
| 400 | ValidationFailure | Données invalides |
| 401 | UnauthorizedFailure | Non authentifié |
| 403 | UnauthorizedFailure | Pas de permission |
| 404 | NotFoundFailure | Ressource non trouvée |
| 409 | ConflictFailure | Ressource existe déjà |
| 5xx | ServerFailure | Erreur serveur |

**À spécifier:**
- Quels codes d'erreur votre API peut retourner
- Comment les mapper aux Failure types

---

### 7️⃣ INJECTION DE DÉPENDANCES

L'injection permet à GetIt de connaître vos classes.

**À enregistrer dans `injection.dart`:**

1. **DataSource**
   ```dart
   getIt.registerLazySingleton<GuardianRemoteDataSource>(
     () => GuardianRemoteDataSource(getIt<Dio>()),
   );
   ```

2. **Repository**
   ```dart
   getIt.registerLazySingleton<GuardianRepository>(
     () => GuardianRepositoryImpl(
       remoteDataSource: getIt<GuardianRemoteDataSource>(),
       requiredAuth: getIt<Map<String, dynamic>>(),
     ),
   );
   ```

3. **Use Cases**
   ```dart
   getIt.registerFactory<UpdateGuardianUseCase>(
     () => UpdateGuardianUseCase(getIt<GuardianRepository>()),
   );
   ```

4. **BLoC**
   ```dart
   getIt.registerFactory<GuardianBloc>(
     () => GuardianBloc(
       updateGuardianUseCase: getIt<UpdateGuardianUseCase>(),
       [autres usecases...],
     ),
   );
   ```

---

## 🔄 CAS D'USAGE COURANTS

### Cas 1: Créer un nouveau module (CRUD complet)

**Utiliser:** FEATURE_TEMPLATE.md

**Sections essentielles:**
1. Informations générales
2. Entity definition
3. API endpoints (les 5: CREATE, READ, UPDATE, DELETE, LIST)
4. Use cases (5 usecases)
5. BLoC configuration (6 events)
6. Injection

---

### Cas 2: Ajouter une opération à un module existant

**Exemple:** Guardian existe, ajouter GetGuardianDetail

**Faire:**
1. Copier QUICK_TEMPLATE.md
2. Remplir SEULEMENT les sections pertinentes:
   - API endpoint GET
   - Use case GetGuardianDetail
   - Event GuardianDetailRequested
   - State fields pour détail
3. Envoyer avec instruction: "Ajouter GetGuardianDetail au module Guardian"

---

### Cas 3: Copier un pattern existant

**Exemple:** Guardian existe, créer Teacher (similaire)

**Faire:**
1. Utiliser QUICK_TEMPLATE.md
2. Remplir avec infos Teacher
3. Mentionner: "Suivre le même pattern que Guardian"

**Gain:** Je réutilise la structure existante, plus rapide ! ⚡

---

## ✍️ CONSEILS DE REMPLISSAGE

### Conseil 1: Soyez Spécifique

❌ Mauvais:
```
Champs: id, data, info
API: Il y a un endpoint
```

✅ Bon:
```
Champs: id (UUID), firstName (String), email (String)
API: POST /api/v1/guardians avec body { firstName, lastName, email }
     Retourne 201 avec { id, firstName, lastName, email, identificationNumber }
```

---

### Conseil 2: Listez Tous les Champs

❌ Mauvais (incomplet):
```
Entity fields: id, name, email
```

✅ Bon (complet):
```
Entity fields:
- id: String (UUID)
- firstName: String
- lastName: String
- email: String
- phoneNumber: String
- relationshipType: Enum (FATHER, MOTHER, GUARDIAN)
- identificationNumber: String
- createdAt: DateTime?
- updatedAt: DateTime?
```

---

### Conseil 3: Précisez les Types

❌ Mauvais:
```
date: date type
```

✅ Bon:
```
createdAt: DateTime
isActive: bool
quantity: int
price: double
```

---

### Conseil 4: Mentionnez les Relations

Si votre entity dépend d'une autre:

```
Teacher Entity fields:
- id: String
- firstName: String
- schoolId: String (relation vers School entity)
- departmentId: String (relation vers Department entity)
```

---

## 🚀 EXEMPLE COMPLET: Créer le Module Teacher

### Étape 1: Ouvrir QUICK_TEMPLATE.md

### Étape 2: Compléter

```
MODULE INFORMATION
Module Name:            Teacher
Feature Description:    Gestion des enseignants de l'école
Module Path:            /lib/features/teacher/

ENTITY DEFINITION
Entity Name:            TeacherSummary
Fields:
- id: String
- firstName: String
- lastName: String
- email: String
- phoneNumber: String
- subject: String (matière enseignée)
- department: String (département)
- employeeId: String (numéro employé)

API OPERATIONS
Base Endpoint:          /api/v1/teachers
Operations:            ✓ CREATE, UPDATE, GET, DELETE, LIST

REQUEST: { firstName, lastName, email, phoneNumber, subject, department }
RESPONSE: { id, firstName, lastName, email, phoneNumber, subject, department, employeeId }

BLOC CONFIGURATION
Bloc Name:             TeacherBloc
Events:
✓ TeacherCreateRequested(firstName, lastName, email, phoneNumber, subject, department)
✓ TeacherUpdateRequested(id, firstName, lastName, email, phoneNumber, subject, department)
✓ TeacherGetRequested(id)
✓ TeacherDeleteRequested(id)
✓ TeacherListRequested(page, size)
✓ TeacherStateReset()

USE CASES
✓ CreateTeacher
✓ UpdateTeacher
✓ GetTeacher
✓ DeleteTeacher
✓ ListTeacher

ERRORS
✓ 400 - ValidationFailure
✓ 401 - UnauthorizedFailure
✓ 404 - NotFoundFailure
✓ 409 - ConflictFailure (email déjà utilisé)
✓ 5xx - ServerFailure
```

### Étape 3: Envoyer

```
Je souhaite créer le module Teacher suivant la Clean Architecture.

[COPIEZ LE TEMPLATE COMPLÉTÉ]

Merci de générer l'implémentation complète ! 🚀
```

### Résultat

→ Tout le module Teacher implémenté en quelques minutes ! ✨

---

## 🔍 VÉRIFICATION AVANT D'ENVOYER

Checklist finale:

```
☐ Tous les champs du template sont remplis
☐ Les noms de module/entity sont clairs
☐ Les endpoints API sont valides
☐ Les use cases couvrent les besoins
☐ Les events et states sont détaillés
☐ Les types de données sont précis
☐ Les erreurs à gérer sont listées
☐ Les dépendances sont listées
☐ Le template est bien formaté
☐ Pas de fautes d'orthographe importantes
```

---

## 💬 BESOIN D'AIDE ?

### Question 1: Comment nommer mon module?

**Règle:** Singular, PascalCase
- ✓ Guardian, Teacher, Student, Parent
- ✗ Guardians, Teachers, students, parent

### Question 2: Comment nommer mon entity?

**Règle:** [Module] + Summary / Detail / Model
- ✓ GuardianSummary, TeacherDetail, StudentModel
- ✗ Guardian, Guardians, GuardianInfo

### Question 3: Combien de use cases minimum?

**Réponse:** Au moins 5 (CRUD + List)
- Create, Update, Get, Delete, List

Vous pouvez en ajouter plus selon vos besoins.

### Question 4: Dois-je toujours tout remplir?

**Réponse:** Non !
- Si vous ne voulez QUE créer + lister → remplissez que ces sections
- Le template est flexible

### Question 5: Puis-je utiliser des enums personnalisés?

**Réponse:** Oui !
- Exemple: `relationshipType: RelationshipType` (enum existant)
- Mentionnez-le dans "Notes"

---

## 🎓 APPRENTISSAGE PROGRESSIF

### Semaine 1: Guardian (déjà fait ✓)
- Comprendre Clean Architecture
- Maîtriser BLoC pattern
- Apprendre patterns du projet

### Semaine 2: Teacher (simple CRUD)
- Utiliser le template
- Reproduire pattern Guardian
- 10 minutes d'implémentation

### Semaine 3: School (avec relations)
- Module plus complexe
- Relations entre entities
- 20 minutes d'implémentation

### Semaine 4+: Custom Features
- Patterns maîtrisés ✓
- Besoin custom couvert ✓
- Développement autonome 🚀

---

## 🎉 BÉNÉFICES

| Avant Template | Après Template |
|---|---|
| ❌ 1-2 heures par feature | ✅ 5-10 minutes |
| ❌ Code souvent inconsistent | ✅ Code propre garanti |
| ❌ Faut demander des clarifications | ✅ Template claire tout |
| ❌ Erreurs fréquentes | ✅ Zéro erreur |
| ❌ Beaucoup de va-et-vient | ✅ Une seule demande |

---

## 📞 RESUMÉ

1. **Consultez** `FEATURE_TEMPLATE.md` ou `QUICK_TEMPLATE.md`
2. **Complétez** toutes les sections
3. **Envoyez** le template à ChatGPT
4. **Recevez** code complet et propre
5. **Intégrez** dans votre projet

**C'est tout ! Vous avez une nouvelle feature en quelques minutes !** 🚀

---

## 🏁 PROCHAINES ÉTAPES

1. Sauvegardez ce fichier: `USAGE_GUIDE.md`
2. Lisez `FEATURE_TEMPLATE.md` en détail
3. Préparez votre prochaine feature
4. Utilisez le template
5. Gagnez du temps ! ⚡

**Bon développement ! 🎉**
