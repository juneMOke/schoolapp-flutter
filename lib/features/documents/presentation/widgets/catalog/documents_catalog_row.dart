import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_action_button.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_labels.dart';
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

    final intent = widget.intent;
    switch (widget.entry.type) {
      case EditiqueDocumentType.enrollmentAttestation:
        await showEditiqueEnrollmentAttestationDialog(
          context,
          enrollmentId: intent.enrollmentId,
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
        break;
    }
  }

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CodeMedallion(code: widget.entry.code, accent: accent),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: AppDimensions.spacingS,
                        runSpacing: AppDimensions.spacingXS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            DocumentsCatalogLabels.titleOf(
                              l10n,
                              widget.entry.type,
                            ),
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _NatureBadge(nature: widget.entry.nature),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        _subtitle(context, l10n),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      DocumentsCatalogRowNotice(action: widget.action),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                DocumentsCatalogActionButton(
                  action: widget.action,
                  onPressed: _onPressed,
                ),
              ],
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
  String _subtitle(BuildContext context, AppLocalizations l10n) {
    final known = widget.action.knownPiece;
    if (known == null) {
      return DocumentsCatalogLabels.hintOf(l10n, widget.entry.type);
    }

    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.fromMillisecondsSinceEpoch(known.createdAt));
    return l10n.documentsLastIssueSubtitle(date, known.number);
  }
}

/// Médaillon 44 dp à l'accent de la pièce, avec sa pastille de code.
///
/// La pastille est **décorative** : le titre complet est toujours lu à côté,
/// donc elle est masquée aux lecteurs d'écran plutôt que de leur faire épeler
/// deux lettres sans contexte.
class _CodeMedallion extends StatelessWidget {
  static const double _size = 44;

  final String code;
  final Color accent;

  const _CodeMedallion({required this.code, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          code,
          style: AppTypography.labelSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Badge de nature (§08).
///
/// Jamais porté par la seule couleur : une icône explicite (cadenas / horloge)
/// double le libellé, conformément au contrat d'accessibilité du module.
class _NatureBadge extends StatelessWidget {
  final EditiqueCatalogNature nature;

  const _NatureBadge({required this.nature});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFige = nature == EditiqueCatalogNature.fige;

    final Color foreground = isFige
        ? AppColors.bleuArdoise
        : AppColors.documentsHorodateText;
    final Color background = isFige
        ? AppColors.bleuArdoiseSoft
        : AppColors.documentsHorodateSoft;
    final Color borderColor = isFige
        ? AppColors.documentsFigeBorder
        : AppColors.documentsHorodateBorder;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFige ? Icons.lock_outline_rounded : Icons.schedule_rounded,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isFige
                ? l10n.documentsNatureArchivedLabel
                : l10n.documentsNatureTimestampedLabel,
            style: AppTypography.labelSmall.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
