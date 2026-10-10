import 'dart:async';

/// Annonce les identifiants dont l'état local vient de changer : geste local,
/// accusé, refus, descente d'un flux.
///
/// Un ensemble vide veut dire « tout peut avoir changé » (école changée,
/// magasin vidé). Un module l'étend pour avoir son propre type dans le
/// conteneur d'injection.
class IdChangeBus {
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  Stream<Set<String>> get stream => _controller.stream;

  void emit(Set<String> ids) {
    if (!_controller.isClosed) _controller.add(ids);
  }

  void emitAll() => emit(const <String>{});

  Future<void> dispose() => _controller.close();
}
