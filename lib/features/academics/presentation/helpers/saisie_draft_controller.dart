import 'package:flutter/foundation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';

/// Une entrée du brouillon de saisie (spec §12) : la saisie brute d'un champ +
/// une éventuelle absence. Le **statut** et les **erreurs** ne sont jamais
/// stockés — ils sont dérivés (cf. [SaisieDraftController]).
@immutable
class DraftEntry {
  final String raw;

  /// `null`, [StatutNote.absentJustifie] ou [StatutNote.absentNonJustifie].
  final StatutNote? absence;

  const DraftEntry({this.raw = '', this.absence});
}

/// Résultat effectif dérivé d'une entrée : statut + points (invariant : statut
/// ≠ NOTEE ⟹ points null).
typedef _Effective = ({StatutNote statut, double? points});

/// Brouillon de saisie **partagé** entre les modes Tableau et Focus (spec §12).
///
/// Source de vérité UNIQUE de l'écran de saisie : la grille persistée vit dans le
/// `SaisieNotesBloc`, mais l'édition en cours (chaînes brutes + absences) vit ici.
/// Statuts, points, erreurs, compteurs et « dirty » sont **dérivés** à la volée.
/// [_baseline] est l'instantané persisté servant à détecter les modifications.
class SaisieDraftController extends ChangeNotifier {
  double _maxPoints = 0;
  List<String> _order = const [];
  final Map<String, DraftEntry> _draft = {};
  final Map<String, DraftEntry> _baseline = {};

  double get maxPoints => _maxPoints;
  List<String> get order => List.unmodifiable(_order);
  int get total => _order.length;

  /// (Ré)initialise le brouillon depuis les lignes persistées (au chargement de
  /// la grille). Brouillon et baseline partent identiques ⟹ « dirty » = false.
  void initialize(List<NoteEleveRow> rows, double maxPoints) {
    _maxPoints = maxPoints;
    _order = rows.map((r) => r.studentId).toList(growable: false);
    _draft
      ..clear()
      ..addEntries(
        rows.map((r) => MapEntry(r.studentId, _entryFromNote(r.note))),
      );
    _baseline
      ..clear()
      ..addEntries(_draft.entries.map((e) => MapEntry(e.key, e.value)));
    notifyListeners();
  }

  /// Recale la baseline (et le brouillon canonique) des lignes **enregistrées
  /// avec succès**, à partir de leur note persistée. Les lignes en échec sont
  /// laissées telles quelles : elles restent « dirty » (rien n'est perdu).
  void commitSaved(Iterable<String> savedIds, List<NoteEleveRow> rows) {
    final byId = {for (final r in rows) r.studentId: r};
    for (final id in savedIds) {
      final row = byId[id];
      if (row == null) continue;
      final entry = _entryFromNote(row.note);
      _draft[id] = entry;
      _baseline[id] = entry;
    }
    notifyListeners();
  }

  DraftEntry entryFor(String id) => _draft[id] ?? const DraftEntry();
  String rawOf(String id) => entryFor(id).raw;
  StatutNote? absenceOf(String id) => entryFor(id).absence;

  /// Statut dérivé (spec §11) : absence choisie > note valide saisie (NOTEE) >
  /// EN_ATTENTE. Une saisie hors bornes reste affichée « En attente » (+ erreur).
  StatutNote statutFor(String id) => _effectiveOf(id).statut;

  /// Points dérivés : non nuls seulement si le statut effectif est NOTEE.
  double? pointsFor(String id) => _effectiveOf(id).points;

  /// `true` si la saisie brute est non vide, sans absence, et hors `[0, max]`
  /// (ou non numérique) — bloque l'enregistrement (spec §8/§10).
  bool hasErrorFor(String id) {
    final e = entryFor(id);
    if (e.absence != null) return false;
    final raw = e.raw.trim();
    if (raw.isEmpty) return false;
    final p = parseNote(raw);
    return p == null || p < 0 || p > _maxPoints;
  }

  /// `true` si l'état effectif diffère de la baseline persistée (comparaison sur
  /// statut+points, pas sur la mise en forme brute).
  bool isDirtyFor(String id) {
    final a = _effective(_draft[id] ?? const DraftEntry());
    final b = _effective(_baseline[id] ?? const DraftEntry());
    return a != b;
  }

  int countOf(StatutNote statut) =>
      _order.where((id) => statutFor(id) == statut).length;

  int get enAttenteCount => countOf(StatutNote.enAttente);

  /// Nombre de lignes « décidées » (notée + absences), pour « x / n saisies ».
  int get enteredCount => total - enAttenteCount;

  int get errorCount => _order.where(hasErrorFor).length;

  bool get dirty => _order.any(isDirtyFor);

  /// Lignes modifiées ET enregistrables (sans erreur), à envoyer au `save()`.
  List<String> get savableDirtyIds =>
      _order.where((id) => isDirtyFor(id) && !hasErrorFor(id)).toList();

  // --- Mutations ------------------------------------------------------------

  /// Saisie d'une note (mode Tableau) : désélectionne toute absence (spec §11).
  void setRaw(String id, String raw) {
    _draft[id] = DraftEntry(raw: raw);
    notifyListeners();
  }

  /// Bascule d'absence (re-cliquer désélectionne → EN_ATTENTE). Choisir une
  /// absence efface les points (invariant 4 du backend, spec §11).
  void toggleAbsence(String id, StatutNote absence) {
    final current = entryFor(id).absence;
    _draft[id] = current == absence
        ? const DraftEntry()
        : DraftEntry(absence: absence);
    notifyListeners();
  }

  /// Remet la ligne à zéro (« Effacer · en attente » du mode Focus).
  void clearEntry(String id) {
    _draft[id] = const DraftEntry();
    notifyListeners();
  }

  /// Ajoute un caractère au pavé numérique (mode Focus) : max 5 caractères, une
  /// seule virgule, jamais en tête. Ignore l'entrée si une absence est posée.
  void appendNoteChar(String id, String ch) {
    final e = entryFor(id);
    if (e.absence != null) return;
    final raw = e.raw;
    if (ch == ',') {
      if (raw.isEmpty || raw.contains(',')) return;
    }
    if (raw.length >= 5) return;
    setRaw(id, raw + ch);
  }

  /// Retire le dernier caractère (Backspace du mode Focus).
  void backspaceNote(String id) {
    final e = entryFor(id);
    if (e.absence != null || e.raw.isEmpty) return;
    setRaw(id, e.raw.substring(0, e.raw.length - 1));
  }

  // --- Dérivations privées --------------------------------------------------

  _Effective _effectiveOf(String id) =>
      _effective(_draft[id] ?? const DraftEntry());

  _Effective _effective(DraftEntry e) {
    if (e.absence != null) return (statut: e.absence!, points: null);
    final raw = e.raw.trim();
    if (raw.isEmpty) return (statut: StatutNote.enAttente, points: null);
    final p = parseNote(raw);
    if (p != null && p >= 0 && p <= _maxPoints) {
      return (statut: StatutNote.notee, points: p);
    }
    // Hors bornes / non numérique : affiché « En attente » (spec §8).
    return (statut: StatutNote.enAttente, points: null);
  }

  DraftEntry _entryFromNote(NoteEleve note) => switch (note.statut) {
    StatutNote.notee => DraftEntry(
      raw: note.pointsObtenus == null ? '' : formatNoteRaw(note.pointsObtenus!),
    ),
    StatutNote.absentJustifie => const DraftEntry(
      absence: StatutNote.absentJustifie,
    ),
    StatutNote.absentNonJustifie => const DraftEntry(
      absence: StatutNote.absentNonJustifie,
    ),
    // EN_ATTENTE, UNKNOWN ou pas encore saisi (null) → champ vide.
    _ => const DraftEntry(),
  };

  /// Convertit une saisie brute (virgule ou point) en `double`, ou `null`.
  static double? parseNote(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Met en forme des points pour l'affichage brut du champ (virgule décimale,
  /// sans zéro superflu) : 7.5 → « 7,5 », 10 → « 10 », 12.25 → « 12,25 ».
  static String formatNoteRaw(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }
}
