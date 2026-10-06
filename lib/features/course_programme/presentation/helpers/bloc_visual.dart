import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellés, aide de saisie et icône d'un type de bloc.
class BlocVisual {
  BlocVisual._();

  /// Le nom court, sur la barre d'ajout.
  static String short(AppLocalizations l10n, ChapitreBlocType type) =>
      switch (type) {
        ChapitreBlocType.titre => l10n.blocTypeTitre,
        ChapitreBlocType.paragraphe => l10n.blocTypeParagraphe,
        ChapitreBlocType.liste => l10n.blocTypeListe,
        ChapitreBlocType.encadre => l10n.blocTypeEncadre,
        ChapitreBlocType.exemple => l10n.blocTypeExemple,
      };

  /// Le nom complet, sur la carte d'édition.
  static String label(AppLocalizations l10n, ChapitreBlocType type) =>
      switch (type) {
        ChapitreBlocType.titre => l10n.blocLabelTitre,
        ChapitreBlocType.liste => l10n.blocLabelListe,
        ChapitreBlocType.exemple => l10n.blocLabelExemple,
        _ => short(l10n, type),
      };

  static String hint(AppLocalizations l10n, ChapitreBlocType type) =>
      switch (type) {
        ChapitreBlocType.titre => l10n.blocHintTitre,
        ChapitreBlocType.paragraphe => l10n.blocHintParagraphe,
        ChapitreBlocType.liste => l10n.blocHintListe,
        ChapitreBlocType.encadre => l10n.blocHintEncadre,
        ChapitreBlocType.exemple => l10n.blocHintExemple,
      };

  static IconData icon(ChapitreBlocType type) => switch (type) {
    ChapitreBlocType.titre => Icons.title_rounded,
    ChapitreBlocType.paragraphe => Icons.notes_rounded,
    ChapitreBlocType.liste => Icons.format_list_bulleted_rounded,
    ChapitreBlocType.encadre => Icons.auto_awesome_outlined,
    ChapitreBlocType.exemple => Icons.edit_outlined,
  };

  /// Lignes visibles du champ en édition (spec §8).
  static int minLines(ChapitreBlocType type) => switch (type) {
    ChapitreBlocType.titre => 1,
    ChapitreBlocType.paragraphe || ChapitreBlocType.liste => 4,
    ChapitreBlocType.encadre || ChapitreBlocType.exemple => 3,
  };
}
