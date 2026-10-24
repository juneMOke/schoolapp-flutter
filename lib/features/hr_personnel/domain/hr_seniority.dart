/// L'ancienneté telle que RH · Personnel la compte : années révolues depuis la
/// date d'entrée, **minimum 0**.
///
/// Diffère de `StaffSeniority` (fichier du personnel) sur un point : une entrée
/// à venir — agent recruté d'avance — compte 0 (« moins d'1 an ») au lieu de
/// passer pour une date absente. Seule une date absente ou illisible rend
/// `null` : c'est elle, et elle seule, qui sort de la moyenne.
abstract final class HrSeniority {
  /// Le jour d'entrée lisible (`YYYY-MM-DD`), ou `null`.
  static DateTime? entryOf(String? entryDate) {
    final day = entryDate?.trim() ?? '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) return null;
    return DateTime.tryParse(day);
  }

  static int? yearsAt(String? entryDate, String today) {
    final entry = entryOf(entryDate);
    final now = DateTime.tryParse(today);
    if (entry == null || now == null) return null;
    if (entry.isAfter(now)) return 0;
    var years = now.year - entry.year;
    final anniversaryPassed =
        now.month > entry.month ||
        (now.month == entry.month && now.day >= entry.day);
    if (!anniversaryPassed) years--;
    return years;
  }
}
