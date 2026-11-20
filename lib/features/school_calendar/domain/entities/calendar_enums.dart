/// Les vocabulaires fermés du calendrier scolaire (contrat back, doc unifié
/// « Agenda & Horaires », §Proposition de contrat).
///
/// Chaque enum se lit et s'écrit par sa valeur wire ; une valeur inconnue
/// retombe sur un repli explicite plutôt que de lever : un serveur plus récent
/// ne doit pas faire tomber un écran de consultation.
library;

/// Nature d'un élément (CAL-R3) — six natures, une couleur chacune.
enum CalendarNature {
  period('PERIOD'),
  assessment('ASSESSMENT'),
  exam('EXAM'),
  holidayBreak('BREAK'),
  publicHoliday('PUBLIC_HOLIDAY'),
  schoolLife('SCHOOL_LIFE');

  const CalendarNature(this.wire);

  final String wire;

  /// Repli sur [schoolLife] : la nature la plus neutre, jamais bloquante.
  static CalendarNature fromWire(String? value) => values.firstWhere(
    (n) => n.wire == value,
    orElse: () => CalendarNature.schoolLife,
  );

  /// Ce que l'école peut créer elle-même ; périodes et fériés ne viennent que
  /// du cadre national (CAL-R3).
  bool get isSchoolCreatable =>
      this != CalendarNature.period && this != CalendarNature.publicHoliday;
}

/// D'où vient un élément (CAL-R4).
enum CalendarSource {
  national('NATIONAL'),
  school('SCHOOL');

  const CalendarSource(this.wire);

  final String wire;

  static CalendarSource fromWire(String? value) =>
      value == national.wire ? national : school;
}

/// Statut **stocké** d'un calendrier. La phase affichée se calcule
/// (`CalendarPhaseRule`).
enum CalendarStatus {
  draft('DRAFT'),
  published('PUBLISHED');

  const CalendarStatus(this.wire);

  final String wire;

  static CalendarStatus fromWire(String? value) =>
      value == published.wire ? published : draft;
}

/// Phase calculée (arbitrage A3).
enum CalendarPhase {
  draft('DRAFT'),
  upcoming('UPCOMING'),
  inForce('IN_FORCE'),
  ended('ENDED'),
  archived('ARCHIVED');

  const CalendarPhase(this.wire);

  final String wire;

  static CalendarPhase fromWire(String? value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => draft);

  /// Un calendrier archivé est en lecture seule (CAL-R13).
  bool get isReadOnly => this == CalendarPhase.archived;
}

/// Rythme des périodes d'un cycle (`SchoolLevelGroup.periodType`).
enum PeriodRhythm {
  semester('SEMESTER'),
  trimester('TRIMESTER');

  const PeriodRhythm(this.wire);

  final String wire;

  static PeriodRhythm? fromWire(String? value) {
    for (final rhythm in values) {
      if (rhythm.wire == value) return rhythm;
    }
    return null;
  }
}

/// État du cadre national d'un calendrier (CAL-D4).
enum FrameworkState {
  integrated('INTEGRATED'),
  awaited('AWAITED');

  const FrameworkState(this.wire);

  final String wire;

  static FrameworkState fromWire(String? value) =>
      value == integrated.wire ? integrated : awaited;
}
