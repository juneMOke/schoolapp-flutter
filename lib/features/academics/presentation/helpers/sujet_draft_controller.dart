import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_limits.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

/// Une question en cours d'édition : ses trois champs ont leur contrôleur.
class SujetQuestionDraft {
  final String id;
  final TextEditingController enonce;
  final TextEditingController points;
  final TextEditingController reponse;

  SujetQuestionDraft(this.id, {SujetQuestion? from})
    : enonce = TextEditingController(text: from?.enonce ?? ''),
      points = TextEditingController(text: _formatPoints(from?.points)),
      reponse = TextEditingController(text: from?.reponseAttendue ?? '');

  /// Points saisis : virgule ou point décimal, deux décimales au plus ; vide
  /// ou illisible → `null`.
  double? get pointsValue {
    final value = double.tryParse(points.text.trim().replaceAll(',', '.'));
    return value == null ? null : SujetLimits.roundPoints(value);
  }

  SujetQuestion toQuestion() {
    final answer = reponse.text.trim();
    return SujetQuestion(
      id: id,
      enonce: enonce.text.trim(),
      points: pointsValue,
      reponseAttendue: answer.isEmpty ? null : answer,
    );
  }

  void dispose() {
    enonce.dispose();
    points.dispose();
    reponse.dispose();
  }

  static String _formatPoints(double? value) {
    if (value == null) return '';
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    return text.replaceAll('.', ',');
  }
}

/// Brouillon de l'éditeur du sujet (spec S3-S4) — **UI seule**, source de
/// vérité de l'éditeur. Barème, questions incomplètes et `isDirty` sont
/// dérivés, jamais stockés. Rien n'est écrit avant « Enregistrer le sujet ».
class SujetDraftController extends ChangeNotifier {
  final EvaluationSujet _initial;
  final double _initialMax;
  final String Function() _newId;

  int? _dureeMinutes;
  List<String> _programme;
  final TextEditingController consignes;
  final List<SujetQuestionDraft> _questions = [];
  double? _adjustedMax;

  SujetDraftController({
    required EvaluationSujet initial,
    required double maxPoints,
    required String Function() newId,
  }) : _initial = initial,
       _initialMax = maxPoints,
       _newId = newId,
       _dureeMinutes = initial.cadre.dureeMinutes,
       _programme = initial.cadre.programme,
       consignes = TextEditingController(text: initial.cadre.consignes ?? '') {
    consignes.addListener(notifyListeners);
    for (final q in initial.questions) {
      _questions.add(_track(SujetQuestionDraft(q.id, from: q)));
    }
  }

  int? get dureeMinutes => _dureeMinutes;
  List<String> get programme => _programme;
  List<SujetQuestionDraft> get questions => List.unmodifiable(_questions);

  /// Maximum à afficher et à enregistrer : l'ajusté, sinon celui de départ.
  double get maxPoints => _adjustedMax ?? _initialMax;

  /// Le maximum a été aligné sur la somme dans ce brouillon.
  double? get adjustedMax => _adjustedMax;

  EvaluationCadre get cadre => EvaluationCadre(
    dureeMinutes: _dureeMinutes,
    programme: _programme,
    consignes: consignes.text,
  ).normalized();

  List<SujetQuestion> get questionValues => [
    for (final q in _questions) q.toQuestion(),
  ];

  SujetBareme get bareme => SujetBareme(
    total: SujetLimits.roundPoints(
      questionValues.fold(0, (sum, q) => sum + (q.points ?? 0)),
    ),
    maxPoints: maxPoints,
  );

  bool get canAddQuestion => _questions.length < SujetLimits.questionsMax;

  int get incompleteCount => questionValues.where((q) => q.isIncomplete).length;

  bool get isDirty =>
      _adjustedMax != null ||
      cadre != _initial.cadre.normalized() ||
      !listEquals(questionValues, _initial.questions);

  void setDuree(int? minutes) {
    _dureeMinutes = minutes;
    notifyListeners();
  }

  void setProgramme(List<String> lines) {
    _programme = lines;
    notifyListeners();
  }

  void addQuestion() {
    if (!canAddQuestion) return;
    _questions.add(_track(SujetQuestionDraft(_newId())));
    notifyListeners();
  }

  void duplicate(SujetQuestionDraft draft) {
    if (!canAddQuestion) return;
    final copy = _track(SujetQuestionDraft(_newId(), from: draft.toQuestion()));
    _questions.insert(_questions.indexOf(draft) + 1, copy);
    notifyListeners();
  }

  void remove(SujetQuestionDraft draft) {
    _questions.remove(draft);
    notifyListeners();
    // Le champ peut encore être monté pendant cette image : libéré après.
    WidgetsBinding.instance.addPostFrameCallback((_) => draft.dispose());
  }

  void move(SujetQuestionDraft draft, int offset) {
    final from = _questions.indexOf(draft);
    final to = from + offset;
    if (from < 0 || to < 0 || to >= _questions.length) return;
    _questions
      ..removeAt(from)
      ..insert(to, draft);
    notifyListeners();
  }

  /// « Ajuster le maximum à X » : aligne le maximum sur la somme des points.
  void adjustMaxToTotal() {
    _adjustedMax = bareme.total;
    notifyListeners();
  }

  SujetQuestionDraft _track(SujetQuestionDraft draft) {
    draft.enonce.addListener(notifyListeners);
    draft.points.addListener(notifyListeners);
    draft.reponse.addListener(notifyListeners);
    return draft;
  }

  @override
  void dispose() {
    consignes.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }
}
