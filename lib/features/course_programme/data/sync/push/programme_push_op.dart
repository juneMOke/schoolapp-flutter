// Les payloads d'outbox du programme et les accusés du serveur. Parsés à la
// main, comme les autres modèles offline : le round-trip `toJson` → `tryParse`
// EST le chemin du push (l'outbox range le texte, le handler le relit).

/// Ce que porte une entrée : un enregistrement ou une suppression.
enum ProgrammePushOp {
  save('save'),
  delete('delete');

  const ProgrammePushOp(this.wireValue);

  final String wireValue;

  static ProgrammePushOp? fromWire(Object? value) =>
      values.where((op) => op.wireValue == value).firstOrNull;
}

/// Lecture tolérante d'un champ texte de payload.
String? pushString(Object? value) => value is String ? value : null;
