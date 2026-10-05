import 'dart:async';

/// Annonce les élèves dont la photo vient de changer sur ce poste : geste
/// local, accusé, refus, descente du flux, copie téléchargée.
///
/// Un ensemble vide veut dire « tout peut avoir changé » (école changée,
/// magasin vidé).
class StudentPhotoChangeBus {
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  Stream<Set<String>> get stream => _controller.stream;

  void emit(Set<String> studentIds) {
    if (!_controller.isClosed) _controller.add(studentIds);
  }

  void emitAll() => emit(const <String>{});

  Future<void> dispose() => _controller.close();
}
