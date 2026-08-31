import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_error_view.dart';

void main() {
  group('classement des échecs', () {
    test('les deux 400 ne mènent pas au même écran', () {
      // C'est toute la raison d'être du code typé. Un champ mal rempli se
      // corrige sur place ; une année déjà existante impose de purger le
      // brouillon et de revenir en arrière.
      expect(
        classifyConfigurationFailure(
          const ApiValidationFailure(code: ApiErrorCode.businessRule),
        ),
        ConfigurationErrorKind.yearAlreadyExists,
      );
      expect(
        classifyConfigurationFailure(
          const ApiValidationFailure(code: ApiErrorCode.validation),
        ),
        isNot(ConfigurationErrorKind.yearAlreadyExists),
      );
    });

    test('un 422 signale un catalogue périmé', () {
      // Le recharger est la seule action qui change quelque chose : un code que
      // le serveur ne connaît pas ne peut venir que d'un cache vieilli.
      expect(
        classifyConfigurationFailure(
          const ApiValidationFailure(code: ApiErrorCode.unprocessable),
        ),
        ConfigurationErrorKind.staleCatalog,
      );
    });

    test('un 429 n\'est ni un réseau ni une panne', () {
      // Le geste qu'il appelle est d'ATTENDRE. Le classer en réseau lui
      // donnerait un « Réessayer », c'est-à-dire l'invitation à reproduire
      // exactement ce qui vient d'être refusé.
      expect(
        classifyConfigurationFailure(const TooManyRequestsFailure()),
        ConfigurationErrorKind.rateLimited,
      );
    });

    test('un 401 mène à la reconnexion, un 403 à personne', () {
      expect(
        classifyConfigurationFailure(const InvalidCredentialsFailure()),
        ConfigurationErrorKind.session,
      );
      expect(
        classifyConfigurationFailure(const UnauthorizedFailure()),
        ConfigurationErrorKind.forbidden,
      );
    });

    test('un sort inconnu est traité comme une panne, pas comme un réseau', () {
      // Une requête partie dont on ignore le sort ne doit surtout pas inviter
      // au rejeu automatique : sur l'activation, elle a pu aboutir.
      expect(
        classifyConfigurationFailure(const UncertainOutcomeFailure()),
        ConfigurationErrorKind.server,
      );
    });

    test('un échec sans code typé se rabat sur le réseau', () {
      expect(
        classifyConfigurationFailure(const NetworkFailure('coupure')),
        ConfigurationErrorKind.network,
      );
      expect(
        classifyConfigurationFailure(const StorageFailure('disque')),
        ConfigurationErrorKind.network,
      );
    });

    test('une panne serveur reste une panne serveur', () {
      expect(
        classifyConfigurationFailure(
          const ApiServerFailure(incidentId: 'INC-1'),
        ),
        ConfigurationErrorKind.server,
      );
    });
  });
}
