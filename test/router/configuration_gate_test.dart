import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/router/app_router.dart';

/// La porte de l'assistant de mise en service.
///
/// Le module Configuration existe pour une école qui n'a pas encore d'année
/// académique. Or c'est exactement l'état dans lequel les deux gardes du
/// contexte académique retiennent tout le monde sur le splash. Sans exception,
/// le module serait inatteignable dans la seule situation qui le justifie —
/// et rien à l'écran ne dirait pourquoi.
///
/// Ce fichier fige la porte **et** son verrou : elle s'ouvre pour qui détient
/// `school.provisioning.write`, et pour personne d'autre.
void main() {
  const provisioner = <String>['school.provisioning.write', 'school.read'];
  const secretary = <String>['enrollment.read', 'student.read'];

  String? redirectFor({
    required String location,
    required List<String>? permissions,
    bool blocking = false,
    bool failure = false,
    AuthStatus status = AuthStatus.authenticated,
  }) {
    return AppRouter.resolveRedirect(
      authStatus: status,
      permissions: permissions,
      academicYearBlocksNavigation: blocking,
      academicYearHasBlockingFailure: failure,
      matchedLocation: location,
      location: Uri.parse(location),
    );
  }

  group('école non paramétrée — le contexte académique est en échec', () {
    test('le promoteur atteint /configuration', () {
      expect(
        redirectFor(
          location: '/configuration',
          permissions: provisioner,
          failure: true,
        ),
        isNull,
      );
    });

    test('le promoteur atteint /configuration pendant le chargement aussi', () {
      // `blocksNavigation` couvre le laps où le référentiel n'a pas encore
      // répondu. Retenir là aussi renverrait l'agent au splash à chaque
      // rafraîchissement du contexte, en plein assistant.
      expect(
        redirectFor(
          location: '/configuration',
          permissions: provisioner,
          blocking: true,
        ),
        isNull,
      );
    });

    test('sans la permission, la porte reste fermée', () {
      expect(
        redirectFor(
          location: '/configuration',
          permissions: secretary,
          failure: true,
        ),
        '/splash',
      );
    });

    test('droits inconnus : la porte reste fermée', () {
      // `null` n'est pas l'ensemble vide : c'est « on ne sait pas encore ».
      // Les deux ferment, mais celui-ci se produit au démarrage — et une porte
      // qui s'ouvre pendant qu'on ignore les droits est une porte ouverte.
      expect(
        redirectFor(
          location: '/configuration',
          permissions: null,
          failure: true,
        ),
        '/splash',
      );
    });

    test('les autres routes restent retenues, promoteur compris', () {
      // La porte ne doit rien ouvrir d'autre : l'exception vaut pour
      // /configuration, pas pour un contexte académique en panne en général.
      expect(
        redirectFor(location: '/home', permissions: provisioner, failure: true),
        '/splash',
      );
      expect(
        redirectFor(
          location: '/finances/facturations',
          permissions: provisioner,
          blocking: true,
        ),
        '/splash',
      );
    });
  });

  group('la porte ne perce pas les gardes qui la précèdent', () {
    test('non authentifié : /configuration renvoie au login', () {
      expect(
        redirectFor(
          location: '/configuration',
          permissions: provisioner,
          failure: true,
          status: AuthStatus.unauthenticated,
        ),
        '/login',
      );
    });

    test('authentification en cours : /configuration attend le splash', () {
      expect(
        redirectFor(
          location: '/configuration',
          permissions: provisioner,
          failure: true,
          status: AuthStatus.loading,
        ),
        '/splash',
      );
    });
  });

  group('les réglages héritent de la garde de l\'assistant', () {
    test('le promoteur atteint /configuration/settings', () {
      expect(
        redirectFor(
          location: '/configuration/settings',
          permissions: provisioner,
        ),
        isNull,
      );
    });

    test('sans la permission, les réglages sont fermés', () {
      // Même geste, même autorité : la garde se lit sur le premier segment,
      // qui est celui de l'assistant.
      expect(
        redirectFor(
          location: '/configuration/settings',
          permissions: secretary,
        ),
        '/home',
      );
    });
  });

  group('école déjà paramétrée — le contexte académique est résolu', () {
    test('le promoteur rouvre /configuration comme réglages', () {
      expect(
        redirectFor(location: '/configuration', permissions: provisioner),
        isNull,
      );
    });

    test('sans la permission, /configuration renvoie à l\'accueil', () {
      // Pas au splash : l'application est utilisable, c'est cette route-là qui
      // ne l'est pas. La garde générale de fin de fonction s'en charge.
      expect(
        redirectFor(location: '/configuration', permissions: secretary),
        '/home',
      );
    });
  });
}
