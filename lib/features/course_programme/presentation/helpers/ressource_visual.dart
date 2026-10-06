import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Icône et libellé d'un type de ressource.
class RessourceVisual {
  RessourceVisual._();

  static IconData icon(RessourceType type) => switch (type) {
    RessourceType.document => Icons.description_outlined,
    RessourceType.lien => Icons.link_rounded,
    RessourceType.manuel => Icons.menu_book_outlined,
  };

  static String label(AppLocalizations l10n, RessourceType type) =>
      switch (type) {
        RessourceType.document => l10n.ressourceTypeDocument,
        RessourceType.lien => l10n.ressourceTypeLien,
        RessourceType.manuel => l10n.ressourceTypeManuel,
      };
}
