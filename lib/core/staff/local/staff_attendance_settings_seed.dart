/// Les réglages du Pointage d'une école tels que le socle les sert (section
/// `staffAttendanceSettings`) : l'heure de début des cours et la tolérance.
///
/// Vit dans le socle et non dans le module RH, pour la même raison que
/// `StaffDocumentTypeLocalModel` : la descente du référentiel ne doit importer
/// aucun module métier — elle reçoit une fonction qui range ces valeurs.
class StaffAttendanceSettingsSeed {
  /// `HH:mm`.
  final String startTime;
  final int toleranceMinutes;

  const StaffAttendanceSettingsSeed({
    required this.startTime,
    required this.toleranceMinutes,
  });

  static final RegExp _time = RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$');

  /// La section du socle, ou `null` quand elle n'est pas communiquée ou
  /// illisible : le cache reste alors tel quel.
  static StaffAttendanceSettingsSeed? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final start = raw['startTime'];
    final tolerance = raw['toleranceMinutes'];
    if (start is! String ||
        !_time.hasMatch(start.trim()) ||
        tolerance is! num) {
      return null;
    }
    // `08:00:00` comme `8:00` se rangent `08:00` : la forme du fil.
    final parts = start.trim().split(':');
    return StaffAttendanceSettingsSeed(
      startTime: '${parts[0].padLeft(2, '0')}:${parts[1]}',
      toleranceMinutes: tolerance.toInt(),
    );
  }
}
