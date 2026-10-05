import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// D'où un avatar tire la photo d'une personne.
///
/// Le socle n'en connaît que le contrat : la photo des élèves est un module à
/// part, qui l'implémente et la pose à la racine par [PersonPhotoScope]. Sans
/// portée, ou sans photo, l'avatar garde ses initiales — c'est la règle, la
/// photo l'exception.
abstract interface class PersonPhotoSource {
  /// Clé de la photo à montrer pour [personId] : elle change quand la photo
  /// change, et vaut `null` quand il n'y en a pas.
  ValueListenable<String?> photoKeyOf(String personId);

  /// Les octets de la photo de [personId] à afficher sur [diameter] dp, ou
  /// `null` s'ils ne sont pas disponibles. Le même tableau est rendu tant que
  /// la photo ne change pas : c'est ce qui laisse le cache d'images le servir
  /// sans le décoder de nouveau.
  Future<Uint8List?> photoBytesOf(String personId, {required double diameter});

  /// Les octets déjà en mémoire, sans attendre — `null` s'il faut passer par
  /// [photoBytesOf]. Une ligne de liste qui revient à l'écran se dessine
  /// ainsi directement avec sa photo, sans repasser par le squelette.
  Uint8List? peekPhotoBytes(String personId, {required double diameter});
}

/// Pose une [PersonPhotoSource] pour tout le sous-arbre.
class PersonPhotoScope extends InheritedWidget {
  final PersonPhotoSource source;

  const PersonPhotoScope({
    super.key,
    required this.source,
    required super.child,
  });

  static PersonPhotoSource? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PersonPhotoScope>()?.source;

  @override
  bool updateShouldNotify(PersonPhotoScope oldWidget) =>
      source != oldWidget.source;
}
