/// Motif pour lequel le serveur refuse une correction de niveau — liste
/// fermée, **422 terminal** (contrat « Changer un élève de niveau », lot B).
///
/// Le geste est jugé dans l'ordre des gardes ; la première qui tombe donne le
/// code. Le seul 409, `ENROLLMENT_NOT_YET_SYNCED`, n'est pas un refus mais une
/// attente : il ne figure pas ici, le gestionnaire d'outbox le lit à part.
///
/// La valeur sur le fil ne se renomme pas. Un code inconnu (serveur plus récent,
/// ou statut HTTP rangé faute de code) se lit `null` : l'écran affiche alors le
/// message générique plutôt que de faire lever la lecture.
enum LevelCorrectionRefusal {
  /// Préinscription ou inscription annulée.
  enrollmentNotConfirmed('ENROLLMENT_NOT_CONFIRMED'),

  /// Le niveau de départ annoncé n'est plus celui en base : une autre tablette
  /// a corrigé entre-temps.
  staleLevel('STALE_LEVEL'),

  /// Niveau cible identique, d'une autre école ou d'une autre année.
  invalidTargetLevel('INVALID_TARGET_LEVEL'),

  /// La grille du niveau cible est vide : l'élève ne devrait plus rien.
  noTariffForLevel('NO_TARIFF_FOR_LEVEL'),

  /// Un versement vivant existe sur l'année (premier temps).
  hasPayments('LEVEL_CORRECTION_HAS_PAYMENTS'),

  /// Notes, cotes saisies ou bulletin sur l'année.
  hasGrades('LEVEL_CORRECTION_HAS_GRADES'),

  /// L'élève est déjà en classe et le niveau cible en a au moins une : la
  /// classe cible est obligatoire (D3).
  targetClassroomRequired('TARGET_CLASSROOM_REQUIRED'),

  /// La classe cible n'est pas du niveau cible.
  levelMismatch('LEVEL_MISMATCH');

  const LevelCorrectionRefusal(this.wire);

  final String wire;

  static LevelCorrectionRefusal? fromWire(String? value) {
    for (final refusal in values) {
      if (refusal.wire == value) return refusal;
    }
    return null;
  }
}
