import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/router/app_router.dart';
import 'package:school_app_flutter/router/return_location.dart';

/// L'adresse demandée au démarrage survit au splash et à la connexion.
///
/// Sur le web, un F5 sur une fiche ramenait toujours à l'Accueil : le splash
/// oubliait d'où l'on venait. Ce fichier fige le trajet aller-retour, ses
/// garde-fous (lien forgé, permission) et le cas qui ne doit PAS rendre
/// l'adresse : la déconnexion en pleine session.
void main() {
  const cashier = <String>['finance.charge.read', 'finance.payment.write'];
  const teacher = <String>['teacher.read'];
  const detail = '/finances/facturations/detail/s1/y1';

  String? redirectFor(
    String location, {
    AuthStatus status = AuthStatus.authenticated,
    List<String>? permissions = cashier,
    bool blocking = false,
    bool isColdStart = false,
  }) {
    final uri = Uri.parse(location);
    return AppRouter.resolveRedirect(
      authStatus: status,
      permissions: permissions,
      academicYearBlocksNavigation: blocking,
      academicYearHasBlockingFailure: false,
      matchedLocation: uri.path,
      location: uri,
      isColdStart: isColdStart,
    );
  }

  group('sanitizeReturnLocation', () {
    test('garde un chemin interne et sa requête', () {
      expect(
        sanitizeReturnLocation('/enrollments/x?origin=pre'),
        '/enrollments/x?origin=pre',
      );
    });

    test('refuse les adresses externes ou forgées', () {
      for (final forged in [
        'https://evil.example/x',
        '//evil.example/x',
        'finances/x',
        '',
        null,
      ]) {
        expect(sanitizeReturnLocation(forged), isNull, reason: '$forged');
      }
    });

    test('refuse le parcours d\'entrée et l\'Accueil nu', () {
      for (final entry in [
        '/splash',
        '/login',
        '/forgot-password/otp',
        '/home',
      ]) {
        expect(sanitizeReturnLocation(entry), isNull, reason: entry);
      }
    });
  });

  group('aller-retour au démarrage', () {
    test('le F5 sur une fiche passe par le splash en gardant l\'adresse', () {
      expect(
        redirectFor(detail, status: AuthStatus.initial, isColdStart: true),
        withReturnLocation('/splash', detail),
      );
    });

    test('une fois la session prête, le splash rend l\'adresse', () {
      expect(redirectFor(withReturnLocation('/splash', detail)), detail);
    });

    test(
      'le contexte académique qui charge retient sans perdre l\'adresse',
      () {
        final splash = withReturnLocation('/splash', detail);
        expect(redirectFor(splash, blocking: true), isNull);
        expect(redirectFor(splash), detail);
      },
    );

    test(
      'session expirée : la connexion hérite de l\'adresse, puis la rend',
      () {
        final login = withReturnLocation('/login', detail);
        expect(
          redirectFor(
            withReturnLocation('/splash', detail),
            status: AuthStatus.unauthenticated,
          ),
          login,
        );
        // Pendant la soumission, le splash garde encore l'adresse.
        expect(
          redirectFor(login, status: AuthStatus.loading),
          withReturnLocation('/splash', detail),
        );
        expect(redirectFor(login), detail);
      },
    );

    test('la garde de permission s\'applique à l\'adresse rendue', () {
      expect(
        redirectFor(
          withReturnLocation('/splash', detail),
          permissions: teacher,
        ),
        '/home',
      );
    });

    test('sans adresse en attente, on arrive à l\'Accueil', () {
      expect(redirectFor('/splash'), '/home');
      expect(redirectFor('/login'), '/home');
    });
  });

  group('en pleine session', () {
    test('la déconnexion depuis une page ne lègue pas l\'adresse', () {
      // `AuthLogoutRequested` passe par `loading` puis `unauthenticated`.
      expect(redirectFor(detail, status: AuthStatus.loading), '/splash');
      expect(redirectFor(detail, status: AuthStatus.unauthenticated), '/login');
    });

    test('un contexte académique qui se recharge renvoie au splash nu', () {
      expect(redirectFor(detail, blocking: true), '/splash');
    });
  });

  group('écrans de la coquille', () {
    const facturations = '/home/facturations';

    test('F5 sur un écran de la coquille y ramène', () {
      final splash = redirectFor(
        facturations,
        status: AuthStatus.initial,
        isColdStart: true,
      );
      expect(splash, withReturnLocation('/splash', facturations));
      expect(redirectFor(splash!), facturations);
    });

    test('un écran hors des droits renvoie à l\'Accueil', () {
      expect(redirectFor(facturations, permissions: teacher), '/home');
      expect(redirectFor(facturations), isNull);
    });
  });
}
