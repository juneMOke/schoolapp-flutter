import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/services/contenu_limits.dart';

/// Un bloc en cours d'édition : son texte (une liste, un élément par ligne)
/// dans un contrôleur.
class BlocLine {
  final String id;
  final ChapitreBlocType type;
  final TextEditingController controller;

  BlocLine({required this.id, required this.type, String text = ''})
    : controller = TextEditingController(text: text);

  factory BlocLine.of(ChapitreBloc bloc) => BlocLine(
    id: bloc.id,
    type: bloc.type,
    text: bloc.type == ChapitreBlocType.liste
        ? bloc.items.join('\n')
        : bloc.texte,
  );

  ChapitreBloc toBloc() => type == ChapitreBlocType.liste
      ? ChapitreBloc(
          id: id,
          type: type,
          items: [
            for (final line in controller.text.split('\n'))
              if (line.trim().isNotEmpty) line.trim(),
          ],
        )
      : ChapitreBloc(id: id, type: type, texte: controller.text.trim());
}

/// Le brouillon du contenu rédigé, gardé **en mémoire** pendant la frappe :
/// il ne part qu'au « Terminer », ou après un temps sans frappe. Prévient
/// ses écouteurs à chaque changement (frappe, ajout, ordre, retrait).
class ContenuDraft extends ChangeNotifier {
  /// Le temps sans frappe au bout duquel le brouillon part de lui-même.
  static const Duration autosaveDelay = Duration(seconds: 2);

  final String Function() _newId;
  final List<BlocLine> lines;

  ContenuDraft(List<ChapitreBloc> blocs, {required String Function() newId})
    : _newId = newId,
      lines = [for (final bloc in blocs) BlocLine.of(bloc)] {
    for (final line in lines) {
      line.controller.addListener(notifyListeners);
    }
  }

  /// Les blocs tels qu'ils seront gardés : un bloc vide ne l'est jamais.
  List<ChapitreBloc> get blocs => [
    for (final line in lines)
      if (!line.toBloc().isEmpty) line.toBloc(),
  ];

  bool get canAdd => lines.length < ContenuLimits.maxBlocs;

  bool get tooHeavy => ContenuLimits.tooHeavy(blocs);

  void add(ChapitreBlocType type) {
    if (!canAdd) return;
    final line = BlocLine(id: _newId(), type: type);
    line.controller.addListener(notifyListeners);
    lines.add(line);
    notifyListeners();
  }

  /// Le départ d'un contenu vide : un titre et un paragraphe.
  void seed() {
    add(ChapitreBlocType.titre);
    add(ChapitreBlocType.paragraphe);
  }

  void move(BlocLine line, int offset) {
    final from = lines.indexOf(line);
    final to = from + offset;
    if (from < 0 || to < 0 || to >= lines.length) return;
    lines.insert(to, lines.removeAt(from));
    notifyListeners();
  }

  void remove(BlocLine line) {
    lines.remove(line);
    line.controller.dispose();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final line in lines) {
      line.controller.dispose();
    }
    super.dispose();
  }
}
