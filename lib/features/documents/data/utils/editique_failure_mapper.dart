import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_error_body_decoder.dart';

/// Convertit une [DioException] d'éditique en [Failure] **porteuse du message
/// du serveur**.
///
/// L'intercepteur global de `injection.dart` a déjà classé le statut HTTP, mais
/// il écrase le message par une constante (`'Resource not found'`). Pour
/// l'éditique, ce message est justement l'information utile : « Aucune charge
/// pour l'élève », « devises multiples »… Ce mapper reprend le type de
/// `Failure` décidé par l'intercepteur et lui rend son message d'origine.
class EditiqueFailureMapper {
  const EditiqueFailureMapper._();

  static Failure fromDioException(DioException exception) {
    final serverMessage = EditiqueErrorBodyDecoder.message(
      exception.response?.data,
    );

    final classified = exception.error;
    if (classified is Failure) {
      return serverMessage == null
          ? classified
          : _withMessage(classified, serverMessage);
    }
    return _fromTransport(exception, serverMessage);
  }

  /// Reconstruit la même `Failure` avec le message du serveur.
  ///
  /// Le type est préservé : c'est lui qui pilote l'anatomie d'erreur affichée
  /// (réseau / 401 / 403 / 500), le message n'en est que le détail.
  static Failure _withMessage(Failure failure, String message) {
    return switch (failure) {
      InvalidCredentialsFailure() => InvalidCredentialsFailure(message),
      UnauthorizedFailure() => UnauthorizedFailure(message),
      NotFoundFailure() => NotFoundFailure(message),
      ValidationFailure() => ValidationFailure(message),
      ConflictFailure() => ConflictFailure(message),
      ServerFailure() => ServerFailure(message),
      NetworkFailure() => NetworkFailure(message),
      UncertainOutcomeFailure() => UncertainOutcomeFailure(message),
      AuthFailure() => AuthFailure(message),
      StorageFailure() => StorageFailure(message),
      // Une `Failure` d'un autre type est laissée intacte plutôt que dégradée
      // en type générique : mieux vaut un message par défaut qu'une mauvaise
      // anatomie d'erreur.
      _ => failure,
    };
  }

  /// Échecs sans réponse HTTP exploitable — c'est ici que se joue la distinction
  /// « rien n'est parti » / « le sort est inconnu ».
  static Failure _fromTransport(DioException exception, String? serverMessage) {
    final message = serverMessage ?? _transportMessage(exception.type);

    return switch (exception.type) {
      // La requête n'a jamais atteint le serveur : rejeu sans risque.
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError => NetworkFailure(message),

      // La requête est partie. Le serveur a pu la traiter entièrement avant que
      // la réponse ne se perde ou n'arrive trop tard.
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => UncertainOutcomeFailure(message),

      DioExceptionType.badCertificate => NetworkFailure(message),

      // Annulation explicite : le travail serveur a pu aboutir malgré tout.
      DioExceptionType.cancel => UncertainOutcomeFailure(message),

      // `badResponse` sans `Failure` attachée = statut hors des cas couverts
      // par l'intercepteur global (ex. 3xx inattendu).
      DioExceptionType.badResponse => ServerFailure(message),

      DioExceptionType.unknown => UncertainOutcomeFailure(message),
    };
  }

  static String _transportMessage(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => 'Network error occurred',
      _ => 'Request outcome is unknown',
    };
  }
}
