/// L'ancienneté d'un agent, calculée sur le poste depuis sa date d'entrée —
/// jamais stockée.
abstract final class StaffSeniority {
  /// Années pleines entre [entryDate] et [today] (`YYYY-MM-DD`), ou `null`
  /// si l'une manque ou si l'entrée est à venir.
  static int? yearsAt(String? entryDate, String today) {
    final entry = DateTime.tryParse(entryDate ?? '');
    final now = DateTime.tryParse(today);
    if (entry == null || now == null || entry.isAfter(now)) return null;
    var years = now.year - entry.year;
    final anniversaryPassed =
        now.month > entry.month ||
        (now.month == entry.month && now.day >= entry.day);
    if (!anniversaryPassed) years--;
    return years;
  }
}
