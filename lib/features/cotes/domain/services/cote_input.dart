/// Ce qu'une frappe veut dire pour une cellule de maximum donné.
sealed class CoteInput {
  const CoteInput();
}

/// Champ vide : la cote est vidée.
final class CoteInputEmpty extends CoteInput {
  const CoteInputEmpty();
}

final class CoteInputValue extends CoteInput {
  final double value;

  const CoteInputValue(this.value);
}

/// Hors barème ou illisible : gardée à l'écran, jamais envoyée.
final class CoteInputInvalid extends CoteInput {
  const CoteInputInvalid();
}

final RegExp _coteShape = RegExp(r'^\d*[.,]?\d{0,2}$');

/// Lit une frappe. Virgule et point sont acceptés, deux décimales au plus (au
/// delà, le serveur refuserait `OUT_OF_RANGE`), de 0 au maximum.
CoteInput parseCoteInput(String raw, int max) {
  final text = raw.trim();
  if (text.isEmpty) return const CoteInputEmpty();
  if (!_coteShape.hasMatch(text) || !text.contains(RegExp(r'\d'))) {
    return const CoteInputInvalid();
  }
  final value = double.parse(text.replaceFirst(',', '.'));
  if (toCentis(value) > max * 100) return const CoteInputInvalid();
  return CoteInputValue(value);
}

/// En centièmes entiers : les sommes et les arrondis sont exacts.
int toCentis(double value) => (value * 100).round();

/// « 14 », « 14,5 », « 14,25 » : jamais de zéro inutile.
String formatCentis(int centis) {
  final sign = centis < 0 ? '-' : '';
  final abs = centis.abs();
  final whole = abs ~/ 100;
  final rest = abs % 100;
  if (rest == 0) return '$sign$whole';
  final decimals = rest % 10 == 0
      ? '${rest ~/ 10}'
      : rest.toString().padLeft(2, '0');
  return '$sign$whole,$decimals';
}

String formatCote(double value) => formatCentis(toCentis(value));
