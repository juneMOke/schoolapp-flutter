import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_action_button.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_reissue.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_row_parts.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne de document du catalogue (§07) — l'unité du module.
///
/// Elle possède **son propre** [EditiqueDocumentBloc] : c'est ce qui lui donne
/// un état local `idle | busy | error` indépendant des autres lignes, et ce qui
/// permet à la visionneuse de se greffer dessus sans le fermer en sortant.
class DocumentsCatalogRow extends StatefulWidget {
  final EditiqueCatalogEntry entry;
  final DocumentsCatalogAction action;
  final DocumentsCatalogIntent intent;

  const DocumentsCatalogRow({
    super.key,
    required this.entry,
    required this.action,
    required this.intent,
  });

  @override
  State<DocumentsCatalogRow> createState() => _DocumentsCatalogRowState();
}

class _DocumentsCatalogRowState extends State<DocumentsCatalogRow> {
  late final EditiqueDocumentBloc _bloc = getIt<EditiqueDocumentBloc>();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Vrai quand cette ligne DÉTIENT déjà la pièce demandée.
  ///
  /// Rouvrir la visionneuse doit alors se contenter de réafficher : sur une
  /// pièce horodatée, redemander brûlerait un SECOND numéro de séquence côté
  /// serveur, et le premier — déjà consommé, jamais archivé — serait
  /// définitivement perdu.
  bool get _holdsDocument =>
      _bloc.state.status == EditiqueDocumentStatus.success &&
      _bloc.state.type == widget.entry.type &&
      _bloc.state.document != null;

  /// Ouvre la pièce. Sur une pièce **horodatée**, une confirmation précède
  /// toujours l'appel : le serveur consomme un numéro de séquence avant même de
  /// rendre le PDF, et n'archive rien — deux appuis produisent deux pièces
  /// numérotées distinctes que le client ne reverra jamais.
  ///
  /// Sauf si la pièce est déjà là : on rouvre alors sans rien redemander, et
  /// sans reposer la question de confirmation — il n'y a plus rien à confirmer.
  Future<void> _onPressed() async {
    final reopen = _holdsDocument;
    if (!reopen && widget.action.needsConfirmation && !await _confirm()) return;
    if (!mounted) return;

    // La tablette détient les octets : on les ressort, sans rien demander au
    // serveur. C'est ce qui fait fonctionner ce bouton hors ligne — et ce qui
    // évite, en ligne, un aller-retour pour une pièce qu'on a déjà.
    final cached = widget.action.cachedPiece;
    if (cached != null) {
      await showEditiqueRestitutionDialog(
        context,
        type: widget.entry.type,
        title: _viewerTitle(AppLocalizations.of(context)!),
        documentId: cached.documentId,
        documentNumber: cached.documentNumber,
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
        bloc: _bloc,
        dispatchOnOpen: !reopen,
      );
      return;
    }

    final intent = widget.intent;
    switch (widget.entry.type) {
      case EditiqueDocumentType.enrollmentAttestation:
        await showEditiqueEnrollmentAttestationDialog(
          context,
          enrollmentId: intent.enrollmentId,
          // Attribue la copie locale : sans l'élève, la pièce mise en cache
          // n'est retrouvée par aucun écran.
          studentId: intent.studentId,
          academicYearId: intent.academicYearId,
          bloc: _bloc,
          dispatchOnOpen: !reopen,
        );
      case EditiqueDocumentType.enrollmentSheet:
        await showEditiqueEnrollmentSheetDialog(
          context,
          enrollmentId: intent.enrollmentId,
          studentId: intent.studentId,
          academicYearId: intent.academicYearId,
          bloc: _bloc,
          dispatchOnOpen: !reopen,
        );
      case EditiqueDocumentType.notePerception:
        await showEditiqueNotePerceptionDialog(
          context,
          studentId: intent.studentId,
          academicYearId: intent.academicYearId,
          bloc: _bloc,
          dispatchOnOpen: !reopen,
        );
      case EditiqueDocumentType.accountStatement:
        await showEditiqueAccountStatementDialog(
          context,
          studentId: intent.studentId,
          academicYearId: intent.academicYearId,
          bloc: _bloc,
          dispatchOnOpen: !reopen,
        );
      case EditiqueDocumentType.financialClearance:
        await showEditiqueFinancialClearanceDialog(
          context,
          studentId: intent.studentId,
          academicYearId: intent.academicYearId,
          bloc: _bloc,
          dispatchOnOpen: !reopen,
        );
      // Le reçu ne s'émet jamais d'ici : sa ligne est éteinte par la matrice.
      case EditiqueDocumentType.paymentReceipt:
      // Le reçu de VENTE non plus, et pour une raison de plus : il ne désigne
      // aucun élève, donc rien de ce dossier ne pourrait l'émettre. Il se
      // réclame depuis la caisse, sur l'identifiant de la vente.
      case EditiqueDocumentType.saleReceipt:
        break;
    }
  }

  /// Titre de la visionneuse pour ce type. Les cinq entrées d'émission le
  /// posent chacune ; la restitution, qui les traverse toutes, doit le choisir.
  String _viewerTitle(AppLocalizations l10n) =>
      DocumentsCatalogLabels.titleOf(l10n, widget.entry.type);

  Future<bool> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final isClearance =
        widget.entry.type == EditiqueDocumentType.financialClearance;

    return showAppConfirmationDialog(
      context: context,
      title: l10n.documentsConfirmGenerateTitle(
        DocumentsCatalogLabels.titleOf(l10n, widget.entry.type),
      ),
      // Le quitus porte un avertissement de plus : le serveur l'émet quel que
      // soit le solde, avec la mention « NON EN RÈGLE » si l'élève ne l'est pas.
      // Ce n'est pas une erreur à intercepter, c'est un résultat métier — mais
      // le guichet doit le savoir avant de remettre la pièce à un parent.
      message: isClearance
          ? '${l10n.documentsConfirmGenerateMessage}\n\n'
                '${l10n.documentsConfirmClearanceWarning}'
          : l10n.documentsConfirmGenerateMessage,
      confirmLabel: l10n.documentsConfirmGenerateAction,
      cancelLabel: l10n.documentsConfirmGenerateCancel,
      headerIcon: Icons.receipt_long_outlined,
      confirmIcon: Icons.description_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = DocumentsCatalogLabels.accentOf(widget.entry.type);

    return BlocProvider<EditiqueDocumentBloc>.value(
      value: _bloc,
      child: BlocBuilder<EditiqueDocumentBloc, EditiqueDocumentState>(
        buildWhen: (prev, curr) => prev.status != curr.status,
        builder: (context, state) {
          final hasError = state.status == EditiqueDocumentStatus.failure;
          final busy = state.status == EditiqueDocumentStatus.loading;

          return Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.documentsRowErrorSoft
                  : AppColors.surface,
              border: Border.all(
                color: hasError
                    ? AppColors.documentsRowErrorBorder
                    : AppColors.border,
              ),
              borderRadius: AppRadius.brCard,
            ),
            // Sur un téléphone étroit, le bouton passe sous le texte : à côté,
            // il ne laisse plus au titre que quelques lettres, et déborde dès
            // que le texte est agrandi.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < AppBreakpoints.phoneNarrowMax;
                final mainButton = DocumentsCatalogActionButton(
                  action: widget.action,
                  onPressed: _onPressed,
                );
                final reissueButton = widget.action.reissuablePiece == null
                    ? null
                    : DocumentsCatalogReissueButton(
                        busy: busy,
                        gap: !stacked,
                        onPressed: () => runDocumentsCatalogReissue(
                          context,
                          type: widget.entry.type,
                          action: widget.action,
                          intent: widget.intent,
                          bloc: _bloc,
                        ),
                      );
                final details = DocumentsCatalogRowDetails(
                  title: DocumentsCatalogLabels.titleOf(
                    l10n,
                    widget.entry.type,
                  ),
                  nature: widget.entry.nature,
                  subtitle: _subtitle(context, l10n),
                  action: widget.action,
                  footer: stacked
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.spacingS,
                          ),
                          child: Wrap(
                            spacing: AppDimensions.spacingS,
                            runSpacing: AppDimensions.spacingS,
                            children: [mainButton, ?reissueButton],
                          ),
                        )
                      : reissueButton,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DocumentsCatalogCodeMedallion(
                      code: widget.entry.code,
                      accent: accent,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(child: details),
                    if (!stacked) ...[
                      const SizedBox(width: AppDimensions.spacingM),
                      mainButton,
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Une seule phrase, par ordre de priorité : la dernière émission connue,
  /// sinon la phrase d'aide qui explique la nature de la pièce.
  ///
  /// « Jamais émis pour cet élève » n'est **jamais** affirmé : aucun endpoint ne
  /// liste les pièces d'un élève, donc la tablette ne peut pas le savoir. Elle
  /// ne dit que ce dont elle a la trace.
  ///
  /// L'édition s'ajoute quand la pièce en vigueur n'est pas la première : une
  /// pièce réémise garde son numéro, et seule l'édition dit laquelle circule.
  String _subtitle(BuildContext context, AppLocalizations l10n) {
    final known = widget.action.knownPiece;
    final edition = widget.action.currentEdition;
    final base = known == null
        ? DocumentsCatalogLabels.hintOf(l10n, widget.entry.type)
        : l10n.documentsLastIssueSubtitle(
            MaterialLocalizations.of(context).formatMediumDate(
              DateTime.fromMillisecondsSinceEpoch(known.createdAt),
            ),
            known.number,
          );
    return edition == null
        ? base
        : '$base · ${l10n.documentsCurrentEdition(edition)}';
  }
}
