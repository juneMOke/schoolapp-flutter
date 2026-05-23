# CLAUDE.md — module `auth`

Spécifique au module d'authentification. Lire le `CLAUDE.md` racine et `AGENTS.md` pour les règles globales.

---

## Périmètre du module

- Login (email + password)
- Vérification de session au démarrage (`AuthCheckRequested`)
- Logout
- Forgot password en 3 étapes : génération OTP → validation OTP → reset password
- Stockage sécurisé de la session (token + infos user) dans `FlutterSecureStorage`

## Structure interne particulière

Le module a **deux BLoCs distincts** (séparation volontaire) :

| BLoC | Périmètre |
|---|---|
| `AuthBloc` | Login, logout, check session, reset password (étape finale) |
| `ForgotPasswordBloc` | Génération + validation OTP (étapes 1 et 2 du reset) |

Et **deux remote data sources** :

- `AuthRemoteDataSource` — login, logout, check session
- `ForgotPasswordRemoteDataSource` — OTP + reset password

→ Ne pas fusionner. Le découplage isole le flow OTP qui n'a pas la même durée de vie qu'une session.

## Flow OTP (forgot password)

```
ForgotPasswordEmailPage
  → ForgotPasswordBloc : GenerateOtpRequested(email)
  → email envoyé · navigation vers ForgotPasswordOtpPage
  → ForgotPasswordBloc : ValidateOtpRequested(email, otpCode)
  → retour d'un otpToken (à conserver dans le state)
  → navigation vers ResetPasswordPage
  → AuthBloc : AuthResetPasswordRequested(email, newPassword, otpToken)
  → succès → state.unauthenticated → RouterNotifier renvoie vers login
```

**Attention** : `otpToken` est un header (`X-OTP-Token`), pas un body field. Il est passé via `@Header('X-OTP-Token')` dans `ForgotPasswordRemoteDataSource`.

## Coupling avec le reste de l'app

Le `main.dart` écoute `AuthBloc.state.status` et déclenche :

| Transition | Action sur `BootstrapBloc` |
|---|---|
| → `authenticated` | `BootstrapRemoteCurrentYearRequested` + `BootstrapRemotePreviousYearRequested` |
| → `unauthenticated` | `BootstrapResetRequested` |

→ **Toute modification de `AuthStatus`** doit être vérifiée contre :
- `main.dart` (listener)
- `app_router.dart` (`RouterNotifier`, logique de redirect)
- `bootstrap_bloc.dart` (réactions)

## Token & session

Géré par `TokenStorageService` (wrap de `FlutterSecureStorage`).
Clés stockées (toutes définies dans `AppConstants`) :

```
accessTokenKey, tokenTypeKey, expiresInKey,
userEmailKey, userFirstNameKey, userLastNameKey,
userRoleKey, userSchoolIdKey
```

→ Toute nouvelle donnée user à persister : ajouter la clé dans `AppConstants` ET les 3 méthodes du service (`save`, `read`, `clear`).

L'expiration JWT est vérifiée au démarrage via `CheckAuthStatusUseCase`. Si expiré → session clearée → unauthenticated.

## Interceptor Dio

L'auth est appliquée via un interceptor dans `injection.dart` :
- Une requête avec `options.extra['requiresAuth'] == true` reçoit `Authorization: Bearer {token}`
- Le marker s'injecte via `getIt<Map<String, dynamic>>()` (alias `RequestOptionsExtra.auth()`)

→ Les endpoints d'auth eux-mêmes (login, generateOtp, validateOtp, resetPassword) **ne portent pas** ce marker — ils sont publics ou utilisent un `X-OTP-Token` à la place.

## Failures à mapper dans les BLoCs

```dart
InvalidCredentialsFailure → 'Identifiants incorrects'   // login
UnauthorizedFailure       → 'Accès non autorisé'        // token invalide
AuthFailure               → 'Erreur d''authentification'
NetworkFailure            → 'Vérifiez votre connexion'
ServerFailure             → 'Erreur serveur'
StorageFailure            → 'Erreur de stockage local'  // FlutterSecureStorage
```

Tout via `AppLocalizations` — pas de string en dur.

## Pages

| Page | BLoC | Notes |
|---|---|---|
| `LoginPage` | `AuthBloc` | Entrée principale |
| `ForgotPasswordEmailPage` | `ForgotPasswordBloc` | Étape 1 du flow OTP |
| `ForgotPasswordOtpPage` | `ForgotPasswordBloc` | Étape 2 — saisie code OTP |
| `ResetPasswordPage` | `AuthBloc` | Étape 3 — utilise l'`otpToken` validé |

Toutes minces, délèguent aux widgets (`AppTitle`, `AuthErrorBanner`, etc.).

## Pièges fréquents

1. **`AuthStatus.failure` ≠ `AuthStatus.unauthenticated`** — `failure` garde le user en mémoire, `unauthenticated` le clear. Ne pas confondre.
2. **`AuthCheckRequested` est idempotent** — toujours déclenché au démarrage dans `main.dart`. Ne pas en ajouter ailleurs.
3. **L'`otpToken` n'est valable qu'une fois** — si reset échoue, le user doit refaire validate OTP.
4. **Ne pas appeler `_bootstrapBloc.add(...)` depuis `AuthBloc`** — le couplage passe par le listener dans `main.dart`. Sens unique.
5. **Le router redirige sur `AuthStatus`** — émettre une transition de status incorrecte casse la navigation.
