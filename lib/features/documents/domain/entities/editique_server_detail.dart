import 'package:school_app_flutter/core/error/failures.dart';

/// Extrait le **message réellement renvoyé par le serveur** d'un échec
/// d'émission, ou `null` s'il n'y en a pas.
///
/// La couche data décode ce message avec soin (`EditiqueErrorBodyDecoder` puis
/// `EditiqueFailureMapper`) parce que c'est souvent la seule information utile :
/// « Aucune charge pour l'élève », « devises multiples ». L'anatomie d'erreur,
/// elle, ne sait dire que la famille (réseau / 401 / 403 / 500). Sans ce
/// passage, tout ce travail de décodage était jeté au seuil de la présentation.
///
/// Deux garde-fous, parce qu'un message brut ne doit jamais être affiché à
/// l'aveugle :
///
/// 1. **Aucun détail sur un échec de transport.** [NetworkFailure] et
///    [UncertainOutcomeFailure] naissent d'une requête sans réponse HTTP : il
///    n'y a pas de corps à décoder, donc pas de message serveur. Leur `message`
///    est soit une constante technique en anglais, soit la pré-garde de
///    connectivité du repository — deux textes que l'anatomie dit déjà mieux.
///
/// 2. **Aucun détail quand le message est la valeur par défaut de sa classe.**
///    La comparaison se fait contre une instance neuve du même type plutôt que
///    contre une chaîne recopiée : si la constante de `failures.dart` change, ce
///    filtre suit sans qu'on ait à y penser.
abstract final class EditiqueServerDetail {
  static String? of(Failure failure) {
    final defaultMessage = _defaultMessageOf(failure);
    if (defaultMessage == null) return null;

    final message = failure.message.trim();
    if (message.isEmpty || message == defaultMessage) return null;
    return message;
  }

  /// Message par défaut du type de [failure], ou `null` quand ce type ne peut
  /// pas porter de détail serveur (échecs de transport).
  static String? _defaultMessageOf(Failure failure) => switch (failure) {
    NetworkFailure() || UncertainOutcomeFailure() => null,
    InvalidCredentialsFailure() => const InvalidCredentialsFailure().message,
    UnauthorizedFailure() => const UnauthorizedFailure().message,
    NotFoundFailure() => const NotFoundFailure().message,
    ValidationFailure() => const ValidationFailure().message,
    ConflictFailure() => const ConflictFailure().message,
    ServerFailure() => const ServerFailure().message,
    _ => null,
  };
}
