# Template de Demande - Feature Module Clean Architecture

Ce template vous permet de me demander l'implémentation complète d'une feature (module) suivant la Clean Architecture du projet.

---

## 📋 TEMPLATE À COMPLÉTER

### 1️⃣ INFORMATIONS GÉNÉRALES

```
Nom du module: [ex: Parent, Guardian, Teacher]
Localisation: /lib/features/[module_name]/
Description courte: [Décrire le rôle du module]
```

---

### 2️⃣ ENTITY & DATA MODEL

```
Entity name: [ex: ParentSummary]
Entity location: /lib/features/[module_name]/domain/entities/[entity_name].dart

Champs de l'entity:
- String id
- String firstName
- String lastName
- String? surname
- String email
- String phoneNumber
- [Autres champs...]

Notes: [Énumérations, types spéciaux, etc.]
```

---

### 3️⃣ API ENDPOINTS

```
Endpoint base: /api/v1/[resource]

Opérations requises:
- CREATE (POST): /api/v1/[resource]
  Requête JSON:
  {
    "field1": "value",
    "field2": "value"
  }
  Réponse JSON:
  {
    "id": "uuid",
    "field1": "value",
    "field2": "value"
  }

- UPDATE (PUT): /api/v1/[resource]/{id}
  Requête JSON:
  {
    "field1": "value"
  }
  Réponse JSON:
  {
    "id": "uuid",
    "field1": "value"
  }

- GET (GET): /api/v1/[resource]/{id}
  Réponse JSON:
  {
    "id": "uuid",
    "field1": "value"
  }

- DELETE (DELETE): /api/v1/[resource]/{id}
  Réponse: HTTP 204 ou message

- LIST (GET): /api/v1/[resource]?page=0&size=20
  Réponse JSON:
  {
    "content": [...],
    "totalElements": 100
  }
```

---

### 4️⃣ CAS D'USAGE (USE CASES)

```
Use Case 1: Create[ModuleName]
- Entrée: [fields]
- Sortie: [ModuleName] entity
- Erreurs: [Erreur1, Erreur2]

Use Case 2: Update[ModuleName]
- Entrée: id + [fields]
- Sortie: [ModuleName] entity
- Erreurs: [Erreur1, Erreur2]

Use Case 3: Get[ModuleName]
- Entrée: id
- Sortie: [ModuleName] entity
- Erreurs: NotFound, Unauthorized

Use Case 4: Delete[ModuleName]
- Entrée: id
- Sortie: Success/Failure
- Erreurs: NotFound, Unauthorized

Use Case 5: List[ModuleName]
- Entrée: page, size, filters
- Sortie: List<[ModuleName]>
- Erreurs: Validation errors
```

---

### 5️⃣ BLOC EVENTS & STATES

```
Events:
1. [ModuleName]CreateRequested
   - Fields à passer: [field1, field2, ...]
   
2. [ModuleName]UpdateRequested
   - Fields à passer: [id, field1, field2, ...]
   
3. [ModuleName]GetRequested
   - Fields à passer: [id]
   
4. [ModuleName]DeleteRequested
   - Fields à passer: [id]
   
5. [ModuleName]ListRequested
   - Fields à passer: [page, size, filters?]

6. [ModuleName]StateReset
   - Pour réinitialiser l'état

States:
- [ModuleName]Status: initial, loading, success, failure
- [ModuleName]Operation: none, create, update, get, delete, list
- current[ModuleName]: [ModuleName]? (pour get/create/update)
- [moduleName]List: List<[ModuleName]>? (pour list)
- errorMessage: String?
- totalElements: int? (pour list avec pagination)
```

---

### 6️⃣ GESTION DES ERREURS

```
Erreurs métier à gérer:
- ValidationFailure: Données invalides
- UnauthorizedFailure: Pas de permission
- NotFoundFailure: Ressource non trouvée
- NetworkFailure: Problème de connexion
- ServerFailure: Erreur serveur (5xx)
- ConflictFailure: Ressource existe déjà (409)

Erreurs HTTP à mapper:
- 400: ValidationFailure
- 401: UnauthorizedFailure
- 403: UnauthorizedFailure
- 404: NotFoundFailure
- 409: ConflictFailure
- 5xx: ServerFailure
```

---

### 7️⃣ INJECTIONS DE DÉPENDANCES

```
À enregistrer dans injection.dart:

// Data Sources
getIt.registerLazySingleton<[ModuleName]RemoteDataSource>(
  () => [ModuleName]RemoteDataSource(getIt<Dio>()),
);

// Repositories
getIt.registerLazySingleton<[ModuleName]Repository>(
  () => [ModuleName]RepositoryImpl(
    remoteDataSource: getIt<[ModuleName]RemoteDataSource>(),
    requiredAuth: getIt<Map<String, dynamic>>(),
  ),
);

// Use Cases
getIt.registerFactory<Create[ModuleName]UseCase>(
  () => Create[ModuleName]UseCase(getIt<[ModuleName]Repository>()),
);

getIt.registerFactory<Update[ModuleName]UseCase>(
  () => Update[ModuleName]UseCase(getIt<[ModuleName]Repository>()),
);

// BLoCs
getIt.registerFactory<[ModuleName]Bloc>(
  () => [ModuleName]Bloc(
    create[ModuleName]UseCase: getIt<Create[ModuleName]UseCase>(),
    update[ModuleName]UseCase: getIt<Update[ModuleName]UseCase>(),
    [autres usecases...],
  ),
);
```

---

### 8️⃣ STRUCTURE DES DOSSIERS

```
/lib/features/[module_name]/
│
├── domain/
│   ├── entities/
│   │   └── [entity_name].dart
│   ├── repositories/
│   │   └── [module_name]_repository.dart (abstract)
│   └── usecases/
│       ├── create_[module_name]_use_case.dart
│       ├── update_[module_name]_use_case.dart
│       ├── get_[module_name]_use_case.dart
│       ├── delete_[module_name]_use_case.dart
│       └── list_[module_name]_use_case.dart
│
├── data/
│   ├── datasources/
│   │   └── [module_name]_remote_data_source.dart
│   ├── repositories/
│   │   └── [module_name]_repository_impl.dart
│   └── models/
│       ├── [entity_name]_model.dart
│       ├── create_[module_name]_request.dart
│       ├── update_[module_name]_request.dart
│       └── [entity_name]_list_response.dart
│
└── presentation/
    └── bloc/
        ├── [module_name]_bloc.dart
        ├── [module_name]_event.dart
        └── [module_name]_state.dart
```

---

## ✅ CHECKLIST D'IMPLÉMENTATION

- [ ] Entity créée avec tous les champs
- [ ] Models créés (fromJson, toJson, toEntity)
- [ ] Request models créés
- [ ] Remote data source créé (RestApi)
- [ ] Repository abstract créé
- [ ] Repository impl créé avec gestion d'erreurs
- [ ] Tous les use cases créés
- [ ] BLoC créé avec tous les handlers
- [ ] Events créés
- [ ] States créés avec copyWith()
- [ ] Endpoints ajoutés à AppConstants
- [ ] Dépendances enregistrées dans injection.dart
- [ ] Aucune erreur de compilation
- [ ] Code formaté et analysé

---

## 📝 EXEMPLE COMPLET - Module Guardian

```
Nom du module: Enrollment (Tuteur légal)
Localisation: /lib/features/guardian/
Description: Gestion des tuteurs légaux des élèves

Entity: GuardianSummary
Champs:
- String id
- String firstName
- String lastName
- String email
- String phoneNumber
- String relationshipType (enum: FATHER, MOTHER, GUARDIAN, etc.)

API Endpoints:
- POST /api/v1/guardians
- PUT /api/v1/guardians/{id}
- GET /api/v1/guardians/{id}
- DELETE /api/v1/guardians/{id}
- GET /api/v1/guardians?page=0&size=20

Use Cases:
- CreateGuardianUseCase
- UpdateGuardianUseCase
- GetGuardianUseCase
- DeleteGuardianUseCase
- ListGuardianUseCase

Events:
- GuardianCreateRequested(firstName, lastName, email, phoneNumber, relationshipType)
- GuardianUpdateRequested(id, firstName, lastName, email, phoneNumber, relationshipType)
- GuardianGetRequested(id)
- GuardianDeleteRequested(id)
- GuardianListRequested(page, size)
- GuardianStateReset()

States:
- GuardianUpdateStatus: initial, loading, success, failure
- GuardianUpdateOperation: none, create, update, get, delete, list
```

---

## 🎯 BONNES PRATIQUES

✅ **Séparation des responsabilités**
- Data layer ne connaît pas Presentation
- Domain layer indépendant
- Chaque use case = une responsabilité

✅ **Gestion des erreurs**
- Toujours wrapper avec Either<Failure, T>
- Mapper les erreurs HTTP en Failures
- Messages d'erreur détaillés

✅ **Nommage**
- PascalCase pour les classes
- camelCase pour les variables
- Suffixes: Request, Model, Response, UseCase, Repository, DataSource

✅ **Code propre**
- Pas de logique métier dans les models
- Pas de dépendances circulaires
- Fonctions courtes et testables

✅ **Testabilité**
- Interfaces pour toutes les dépendances
- Injection de dépendances
- Pas de singletons directs

---

## 📞 COMMENT UTILISER CE TEMPLATE

Quand vous avez besoin d'implémenter une nouvelle feature:

1. **Remplissez le template** avec vos informations
2. **Copiez-collez le template complété** dans votre demande
3. **Je générerai** toute l'implémentation suivant cette structure
4. **Code garanti** clean, maintenable et sécurisé

---

## 🚀 EXEMPLE DE DEMANDE

```
Je souhaite implémenter le module Guardian suivant la Clean Architecture.

### Informations Générales
Nom: Guardian
Description: Gestion des tuteurs légaux

### Entity
Champs: id, firstName, lastName, email, phoneNumber, relationshipType

### API Endpoints
POST /api/v1/guardians
PUT /api/v1/guardians/{id}
GET /api/v1/guardians/{id}
DELETE /api/v1/guardians/{id}

### Use Cases
- Create, Update, Get, Delete, List

### Events
- GuardianCreateRequested
- GuardianUpdateRequested
- GuardianGetRequested
- GuardianDeleteRequested
- GuardianListRequested

### Erreurs
- ValidationFailure, UnauthorizedFailure, NotFoundFailure

Merci de générer toute l'implémentation !
```

---

## ⚠️ POINTS IMPORTANTS

1. **Toujours utiliser Either<Failure, T>** pour les retours
2. **Toujours gérer les DioException** dans les repositories
3. **Toujours créer des modèles séparés** pour request/response
4. **Toujours utiliser des enums** pour les statuts/opérations
5. **Toujours enregistrer dans injection.dart**
6. **Toujours suivre le naming convention** du projet
7. **Toujours implémenter Equatable** pour les states
8. **Toujours ajouter les constantes** dans AppConstants

---

Vous pouvez maintenant utiliser ce template pour toute nouvelle feature ! 🎉
