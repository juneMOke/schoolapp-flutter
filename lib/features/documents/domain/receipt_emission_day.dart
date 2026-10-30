import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';

/// Le jour d'émission d'une pièce, stocké `AAAA-MM-JJ`.
///
/// Le back le sert comme une **date portée à minuit UTC**
/// (`2026-10-27T00:00:00Z`), déjà prise au jour de l'école (réponse du
/// 2026-10-30) : `emittedAt` du delta éditique, des accusés de versement et de
/// l'en-tête `X-Document-Emitted-At`. Il se lit donc tel quel.
///
/// ⚠️ **Jamais `toLocal()`.** À Kinshasa (UTC+1), la conversion donnerait
/// 01 h 00 le bon jour, et l'erreur passerait inaperçue ; à l'ouest de
/// Greenwich, elle imprimerait la veille. Et il n'en sort aucune heure : ce
/// n'est pas l'instant du scellement.
abstract final class ReceiptEmissionDay {
  /// `2026-10-27T00:00:00Z` → `2026-10-27`, `null` si absent ou illisible.
  ///
  /// Ce sont les dix premiers caractères qui font foi, quel que soit le reste :
  /// un décalage (`…+01:00`) ramené en UTC donnerait la veille. Une valeur qui
  /// n'est pas une chaîne (un nombre, si la sérialisation changeait) vaut une
  /// absence — jamais une levée qui ferait échouer tout l'accusé.
  static String? fromIso(Object? iso) {
    if (iso is! String) return null;
    final match = _leadingDay.firstMatch(iso.trim());
    if (match == null) return null;
    final day = match.group(0)!;
    final parsed = DateTime.tryParse(day);
    // `2026-02-30` se lit 2 mars : un jour qui ne se relit pas pareil est
    // illisible.
    if (parsed == null || DateOnlyJsonHelper.toJson(parsed) != day) {
      return null;
    }
    return day;
  }

  static final RegExp _leadingDay = RegExp(r'^\d{4}-\d{2}-\d{2}');

  /// L'époch ms du cache des pièces (`editique_cache.emitted_at`, lu depuis le
  /// même `emittedAt`), relu en UTC.
  static String? fromEpochMs(int? ms) => ms == null
      ? null
      : DateOnlyJsonHelper.toJson(
          DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        );

  /// `2026-10-27` → la date du 27 octobre 2026 (sans heure), `null` sinon.
  static DateTime? toDate(String? day) {
    final text = day?.trim();
    if (text == null || text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }
}
