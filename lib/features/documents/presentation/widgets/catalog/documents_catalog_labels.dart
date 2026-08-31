import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Traductions et accents du barème (§09), regroupés hors des widgets.
///
/// Une seule table de correspondance par axe : ajouter une pièce au barème ne
/// doit toucher qu'ici et le fichier d'entrées, jamais un widget.
abstract final class DocumentsCatalogLabels {
  static String titleOf(AppLocalizations l10n, EditiqueDocumentType type) =>
      switch (type) {
        EditiqueDocumentType.enrollmentAttestation =>
          l10n.editiqueViewerAttestationTitle,
        EditiqueDocumentType.notePerception =>
          l10n.editiqueViewerNotePerceptionTitle,
        EditiqueDocumentType.paymentReceipt => l10n.editiqueViewerReceiptTitle,
        EditiqueDocumentType.accountStatement =>
          l10n.editiqueViewerStatementTitle,
        EditiqueDocumentType.financialClearance =>
          l10n.editiqueViewerClearanceTitle,
        // Le RV ne figure PAS au catalogue d'un élève : son sujet est le
        // payeur, et il se retrouve depuis la caisse. Le cas est ici parce que
        // le type est commun à toute l'imprimerie, pas parce qu'il s'affiche —
        // `EditiqueCatalogEntry.all` ne le porte pas.
        EditiqueDocumentType.saleReceipt => l10n.editiqueViewerSaleReceiptTitle,
      };

  /// Phrase d'aide : elle explique la **nature** en langage métier, pas la
  /// mécanique. C'est ce qui évite au guichet d'émettre un relevé en croyant
  /// consulter une pièce déjà produite.
  static String hintOf(AppLocalizations l10n, EditiqueDocumentType type) =>
      switch (type) {
        EditiqueDocumentType.enrollmentAttestation =>
          l10n.documentsHintAttestation,
        EditiqueDocumentType.notePerception => l10n.documentsHintNotePerception,
        EditiqueDocumentType.paymentReceipt => l10n.documentsHintReceipt,
        EditiqueDocumentType.accountStatement => l10n.documentsHintStatement,
        EditiqueDocumentType.financialClearance => l10n.documentsHintClearance,
        EditiqueDocumentType.saleReceipt => l10n.documentsHintSaleReceipt,
      };

  static Color accentOf(EditiqueDocumentType type) => switch (type) {
    EditiqueDocumentType.enrollmentAttestation => AppColors.bleuArdoise,
    EditiqueDocumentType.notePerception ||
    EditiqueDocumentType.paymentReceipt ||
    EditiqueDocumentType.accountStatement => AppColors.terreCuite,
    EditiqueDocumentType.financialClearance => AppColors.vertSavane,
    // L'accent de la caisse, pas celui des finances scolaires : la boutique est
    // étanche à la scolarité (invariant I-4), et sa pièce ne doit pas se
    // confondre avec un reçu de frais.
    EditiqueDocumentType.saleReceipt => AppColors.boutiqueActivitesAccent,
  };

  static String groupTitleOf(
    AppLocalizations l10n,
    EditiqueCatalogGroup group,
  ) => switch (group) {
    EditiqueCatalogGroup.scolarite => l10n.documentsGroupScolariteTitle,
    EditiqueCatalogGroup.finances => l10n.documentsGroupFinancesTitle,
  };

  static String groupSubtitleOf(
    AppLocalizations l10n,
    EditiqueCatalogGroup group,
  ) => switch (group) {
    EditiqueCatalogGroup.scolarite => l10n.documentsGroupScolariteSubtitle,
    EditiqueCatalogGroup.finances => l10n.documentsGroupFinancesSubtitle,
  };

  static IconData groupIconOf(EditiqueCatalogGroup group) => switch (group) {
    EditiqueCatalogGroup.scolarite => Icons.school_outlined,
    EditiqueCatalogGroup.finances => Icons.account_balance_outlined,
  };
}
