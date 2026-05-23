# Quick Template - Module Implementation Checklist

## 🎯 QUICK START - À compléter et envoyer

Utilisez ce formulaire simplifié pour des demandes rapides et efficaces.

---

## MODULE INFORMATION

```
Module Name:            [ex: Guardian]
Feature Description:    [Courte description]
Module Path:            /lib/features/[module_name]/
```

---

## ENTITY DEFINITION

```
Entity Name:            [ex: GuardianSummary]
Entity File:            /lib/features/[module]/domain/entities/[entity].dart

Fields (liste complète):
┌─────────────────┬──────────────┬────────────────┐
│ Field Name      │ Type         │ Nullable?      │
├─────────────────┼──────────────┼────────────────┤
│ id              │ String       │ No             │
│ firstName       │ String       │ No             │
│ lastName        │ String       │ No             │
│ email           │ String       │ No             │
│ [Ajouter...]    │              │                │
└─────────────────┴──────────────┴────────────────┘
```

---

## API OPERATIONS

```
Base Endpoint:          /api/v1/[resource]

REQUIRED OPERATIONS (cocher les nécessaires):
☐ CREATE  (POST)   /api/v1/[resource]
☐ UPDATE  (PUT)    /api/v1/[resource]/{id}
☐ GET     (GET)    /api/v1/[resource]/{id}
☐ DELETE  (DELETE) /api/v1/[resource]/{id}
☐ LIST    (GET)    /api/v1/[resource]?page=0&size=20

REQUEST BODY EXAMPLE (si applicable):
{
  "firstName": "string",
  "lastName": "string",
  "email": "string@example.com"
}

RESPONSE BODY EXAMPLE:
{
  "id": "uuid",
  "firstName": "string",
  "lastName": "string",
  "email": "string@example.com"
}

ERRORS TO HANDLE:
☐ 400 - ValidationFailure
☐ 401 - UnauthorizedFailure
☐ 403 - UnauthorizedFailure
☐ 404 - NotFoundFailure
☐ 409 - ConflictFailure
☐ 5xx - ServerFailure
```

---

## USE CASES

```
REQUIRED USE CASES (cocher les nécessaires):
☐ Create[Module]
☐ Update[Module]
☐ Get[Module]
☐ Delete[Module]
☐ List[Module]
☐ [Custom Use Case 1]: ___________________
☐ [Custom Use Case 2]: ___________________

Détails pour custom use cases:
Use Case 1:
  - Input: [fields]
  - Output: [entity]
  - Errors: [error types]

Use Case 2:
  - Input: [fields]
  - Output: [entity]
  - Errors: [error types]
```

---

## BLOC CONFIGURATION

```
Bloc Name:              [Module]Bloc
State Enum Status:      [Module]UpdateStatus: initial, loading, success, failure
State Enum Operation:   [Module]UpdateOperation: none, create, update, get, delete, list

EVENTS REQUIRED (cocher):
☐ [Module]CreateRequested
  └─ Parameters: [list fields]

☐ [Module]UpdateRequested
  └─ Parameters: id, [list fields]

☐ [Module]GetRequested
  └─ Parameters: id

☐ [Module]DeleteRequested
  └─ Parameters: id

☐ [Module]ListRequested
  └─ Parameters: page, size, [filters]

☐ [Module]StateReset
  └─ No parameters

STATE FIELDS:
- status: [Module]UpdateStatus
- operation: [Module]UpdateOperation
- current[Module]: [Module]?
- [module]List: List<[Module]>?
- errorMessage: String?
- totalElements: int?
```

---

## DEPENDENCY INJECTION

```
Enregistrements à ajouter dans injection.dart:

DataSource:
  RemoteDataSource: ☐

Repository:
  Abstract: ☐
  Implementation: ☐

Use Cases:
  ☐ Create[Module]UseCase
  ☐ Update[Module]UseCase
  ☐ Get[Module]UseCase
  ☐ Delete[Module]UseCase
  ☐ List[Module]UseCase

BLoC:
  [Module]Bloc: ☐
```

---

## CONSTANTS & ENDPOINTS

```
Endpoints à ajouter dans AppConstants:

static const String [module]CreateEndpoint = '/api/v1/[resource]';
static const String [module]UpdateEndpoint = '/api/v1/[resource]/{id}';
static const String [module]GetEndpoint = '/api/v1/[resource]/{id}';
static const String [module]DeleteEndpoint = '/api/v1/[resource]/{id}';
static const String [module]ListEndpoint = '/api/v1/[resource]';
```

---

## FILES TO CREATE

```
Structure de fichiers à générer:

Domain Layer:
  ☐ domain/entities/[entity].dart
  ☐ domain/repositories/[module]_repository.dart
  ☐ domain/usecases/create_[module]_use_case.dart
  ☐ domain/usecases/update_[module]_use_case.dart
  ☐ domain/usecases/get_[module]_use_case.dart
  ☐ domain/usecases/delete_[module]_use_case.dart
  ☐ domain/usecases/list_[module]_use_case.dart

Data Layer:
  ☐ data/datasources/[module]_remote_data_source.dart
  ☐ data/repositories/[module]_repository_impl.dart
  ☐ data/models/[entity]_model.dart
  ☐ data/models/create_[module]_request.dart
  ☐ data/models/update_[module]_request.dart
  ☐ data/models/[entity]_list_response.dart

Presentation Layer:
  ☐ presentation/bloc/[module]_bloc.dart
  ☐ presentation/bloc/[module]_event.dart
  ☐ presentation/bloc/[module]_state.dart
```

---

## MODIFICATIONS EXISTANTES

```
Fichiers à modifier:

  ☐ core/constants/app_constants.dart
    → Ajouter les endpoints constants

  ☐ core/di/injection.dart
    → Enregistrer toutes les dépendances

  ☐ [Autres fichiers existants]: _________________
```

---

## SPECIAL REQUIREMENTS

```
Points spéciaux à considérer:

☐ Authentification requise? (requiredAuth)
☐ Pagination/List nécessaire?
☐ Filtres à supporter?
☐ Validations spéciales?
☐ Enums personnalisées? (ex: RelationshipType)
☐ Relations avec autres modules?
☐ Cas d'erreur spéciaux?

Détails:
_________________________________________________________________________
_________________________________________________________________________
_________________________________________________________________________
```

---

## VALIDATION CHECKLIST

Avant d'envoyer, vérifiez:

```
BEFORE SUBMISSION:
☐ Tous les champs du template sont remplis
☐ Les noms suivent la convention du projet (PascalCase, camelCase)
☐ Les endpoints API sont corrects
☐ Les types de données sont explicites
☐ Les erreurs à gérer sont listées
☐ Les use cases couvrent tous les besoins
☐ La structure des dossiers est clara
☐ Les fichiers à créer/modifier sont listés

AFTER IMPLEMENTATION:
☐ Aucune erreur de compilation
☐ flutter analyze ne signale rien
☐ Code formaté avec dart format
☐ Imports organisés
☐ Pas de dépendances circulaires
☐ Tests unitaires possibles
```

---

## EXEMPLE COMPLÉTÉ - Guardian Module

```
╔════════════════════════════════════════════════════════════════╗
║           MODULE INFORMATION                                   ║
╚════════════════════════════════════════════════════════════════╝

Module Name:            Guardian
Feature Description:    Gestion des tuteurs légaux des élèves
Module Path:            /lib/features/guardian/

╔════════════════════════════════════════════════════════════════╗
║           ENTITY DEFINITION                                    ║
╚════════════════════════════════════════════════════════════════╝

Entity Name:            GuardianSummary
Entity File:            /lib/features/guardian/domain/entities/guardian_summary.dart

Fields:
┌─────────────────────┬──────────────┬────────────────┐
│ id                  │ String       │ No             │
│ firstName           │ String       │ No             │
│ lastName            │ String       │ No             │
│ email               │ String       │ No             │
│ phoneNumber         │ String       │ No             │
│ relationshipType    │ String/Enum  │ No             │
│ identificationNum   │ String       │ No             │
└─────────────────────┴──────────────┴────────────────┘

╔════════════════════════════════════════════════════════════════╗
║           API OPERATIONS                                       ║
╚════════════════════════════════════════════════════════════════╝

Base Endpoint:          /api/v1/guardians

OPERATIONS:
✓ CREATE  (POST)   /api/v1/guardians
✓ UPDATE  (PUT)    /api/v1/guardians/{id}
✓ GET     (GET)    /api/v1/guardians/{id}
✓ DELETE  (DELETE) /api/v1/guardians/{id}
✓ LIST    (GET)    /api/v1/guardians?page=0&size=20

REQUEST: { firstName, lastName, email, phoneNumber, relationshipType }
RESPONSE: { id, firstName, lastName, email, phoneNumber, relationshipType, identificationNumber }

╔════════════════════════════════════════════════════════════════╗
║           USE CASES                                            ║
╚════════════════════════════════════════════════════════════════╝

✓ CreateGuardianUseCase
✓ UpdateGuardianUseCase
✓ GetGuardianUseCase
✓ DeleteGuardianUseCase
✓ ListGuardianUseCase

╔════════════════════════════════════════════════════════════════╗
║           BLOC CONFIGURATION                                   ║
╚════════════════════════════════════════════════════════════════╝

Bloc Name:              GuardianBloc

Events:
✓ GuardianCreateRequested(firstName, lastName, email, phoneNumber, relationshipType)
✓ GuardianUpdateRequested(id, firstName, lastName, email, phoneNumber, relationshipType)
✓ GuardianGetRequested(id)
✓ GuardianDeleteRequested(id)
✓ GuardianListRequested(page, size)
✓ GuardianStateReset()

Status: GuardianUpdateStatus (initial, loading, success, failure)
Operation: GuardianUpdateOperation (none, create, update, get, delete, list)
```

---

## 💡 CONSEILS D'UTILISATION

1. **Commencez par l'Entity** → Définissez les champs
2. **Puis l'API** → Connaitre les endpoints
3. **Puis les Use Cases** → Logique métier
4. **Puis le BLoC** → UI coordination
5. **Injection** → Enregistrer tout

**Plus vous êtes précis dans ce template, plus je serai rapide et efficace ! ⚡**

---

## 📤 FORMAT D'ENVOI

Collez ce template COMPLÉTÉ dans votre message à ChatGPT :

```
Je souhaite créer le module [NOM] suivant la Clean Architecture.

[COPIEZ-COLLEZ LE TEMPLATE COMPLÉTÉ ICI]

Merci de générer l'implémentation complète ! 🚀
```

**Résultat : Implementation complète en quelques secondes ! ✨**
