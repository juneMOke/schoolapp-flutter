import 'package:flutter/foundation.dart';

enum CoteStudentFilter { all, todo, done }

/// La recherche et le filtre de la liste des élèves. Tenus au-dessus de la
/// liste : ils survivent quand elle cède la place au sélecteur (rotation,
/// fenêtre rétrécie) et reviennent avec elle ; la page les porte dans
/// l'adresse.
class CoteStudentQuery extends ChangeNotifier {
  String _text;
  CoteStudentFilter _filter;

  CoteStudentQuery({
    String text = '',
    CoteStudentFilter filter = CoteStudentFilter.all,
  }) : _text = text,
       _filter = filter;

  String get text => _text;
  CoteStudentFilter get filter => _filter;

  set text(String value) {
    if (value == _text) return;
    _text = value;
    notifyListeners();
  }

  set filter(CoteStudentFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  /// Tout montrer : recherche vide, aucun filtre.
  void reset() {
    if (_text.isEmpty && _filter == CoteStudentFilter.all) return;
    _text = '';
    _filter = CoteStudentFilter.all;
    notifyListeners();
  }
}
