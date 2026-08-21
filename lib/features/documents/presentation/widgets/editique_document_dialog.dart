import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_preview.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/states/editique_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la visionneuse sur l'attestation d'inscription (AI) d'un dossier.
///
/// Pièce archivée et idempotente : le serveur re-sert les mêmes octets sous le
/// même numéro, donc rouvrir cette modale ne produit jamais de doublon.
Future<void> showEditiqueEnrollmentAttestationDialog(
  BuildContext context, {
  required String enrollmentId,
  String? studentId,
  String? academicYearId,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerAttestationTitle,
    request: EditiqueEnrollmentAttestationRequested(
      enrollmentId: enrollmentId,
      studentId: studentId,
      academicYearId: academicYearId,
    ),
    bloc: bloc,
    dispatchOnOpen: dispatchOnOpen,
  );
}

/// Ouvre la visionneuse sur la note de perception (NP) d'un élève.
///
/// Pièce archivée et idempotente. Le serveur répond 404 quand l'élève n'a
/// aucune charge sur l'année — motif que la modale affiche tel quel.
Future<void> showEditiqueNotePerceptionDialog(
  BuildContext context, {
  required String studentId,
  required String academicYearId,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerNotePerceptionTitle,
    request: EditiqueNotePerceptionRequested(
      studentId: studentId,
      academicYearId: academicYearId,
    ),
    bloc: bloc,
    dispatchOnOpen: dispatchOnOpen,
  );
}

/// Ouvre la visionneuse sur le reçu (RC) d'un paiement.
///
/// L'appelant reste responsable des gardes en amont : un paiement pas encore
/// synchronisé porte un uuid inconnu du serveur et produirait un 404.
Future<void> showEditiquePaymentReceiptDialog(
  BuildContext context, {
  required String paymentId,
  String? studentId,
  String? academicYearId,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerReceiptTitle,
    request: EditiquePaymentReceiptRequested(
      paymentId: paymentId,
      studentId: studentId,
      academicYearId: academicYearId,
    ),
    bloc: bloc,
    dispatchOnOpen: dispatchOnOpen,
  );
}

/// Ouvre la visionneuse sur le quitus financier (QT) d'un élève.
///
/// ⚠️ Mêmes précautions que le relevé : numéro de séquence consommé à chaque
/// appel, pièce jamais archivée. L'appelant doit avoir confirmé l'intention —
/// et, si l'élève n'est pas en règle, l'avoir annoncé : le serveur émettra la
/// pièce quand même, avec la mention « NON EN RÈGLE ».
Future<void> showEditiqueFinancialClearanceDialog(
  BuildContext context, {
  required String studentId,
  required String academicYearId,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerClearanceTitle,
    request: EditiqueFinancialClearanceRequested(
      studentId: studentId,
      academicYearId: academicYearId,
    ),
    bloc: bloc,
    dispatchOnOpen: dispatchOnOpen,
  );
}

/// Ouvre la visionneuse sur le relevé de compte (RL) d'un élève.
///
/// ⚠️ L'appelant doit avoir confirmé l'intention **avant** d'appeler : le
/// serveur consomme un numéro de séquence à chaque émission et n'archive pas la
/// pièce. Ouvrir cette modale, c'est déjà en produire une.
Future<void> showEditiqueAccountStatementDialog(
  BuildContext context, {
  required String studentId,
  required String academicYearId,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerStatementTitle,
    request: EditiqueAccountStatementRequested(
      studentId: studentId,
      academicYearId: academicYearId,
    ),
    bloc: bloc,
    dispatchOnOpen: dispatchOnOpen,
  );
}

/// Ouvre la visionneuse sur une pièce **déjà scellée**, sans rien produire.
///
/// C'est l'autre verbe de D-1 : la copie locale d'abord, le re-téléchargement
/// ensuite. Rien n'est émis, aucun numéro n'est consommé, et l'ouverture
/// fonctionne **hors ligne** quand la tablette détient la pièce.
///
/// Réservé aux pièces que le serveur archive : un relevé ou un quitus est
/// recalculé à chaque demande et n'a pas de version à ressortir.
Future<void> showEditiqueRestitutionDialog(
  BuildContext context, {
  required EditiqueDocumentType type,
  required String title,
  String? documentId,
  String? documentNumber,
  String? studentId,
  String? academicYearId,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: title,
    request: EditiqueDocumentRestitutionRequested(
      type: type,
      documentId: documentId,
      documentNumber: documentNumber,
      studentId: studentId,
      academicYearId: academicYearId,
    ),
    bloc: bloc,
    dispatchOnOpen: dispatchOnOpen,
  );
}

/// Socle commun des visionneuses.
///
/// L'émission est déclenchée à l'ouverture. Deux régimes de propriété :
///
/// - **sans [bloc]** — la modale crée le sien et le ferme avec elle : une seule
///   pièce vivante en mémoire, régime des appels ponctuels depuis la Facturation ;
/// - **avec [bloc]** — la modale se greffe sur une instance possédée par un
///   écran (`BlocProvider.value`, qui ne ferme pas ce qu'il n'a pas créé). C'est
///   ce que réclame le catalogue de l'élève : chaque ligne possède son BLoC pour
///   garder son état `idle | busy | error`, et la visionneuse n'est qu'une vue
///   de plus sur cet état — fermer la modale ne doit pas l'effacer.
///
/// Hors ligne, aucune pièce ne peut être produite — le repository le tranche en
/// pré-garde et la modale affiche l'anatomie réseau sans attente.
///
/// ⚠️ **Cette visionneuse ne passe PAS par `EteeloDialogBody`, contrairement aux
/// six autres modales du même lot (B-9), et ce n'est pas un oubli.** Son corps
/// n'est pas un document qui coule : c'est `PdfPreview`, une fenêtre qui gère
/// son propre défilement et exige une hauteur BORNÉE. La disposition défilante
/// du socle lui offrirait une hauteur infinie — soit une exception de layout,
/// soit un défilement dans un défilement, la pathologie même que ce socle
/// documente.
///
/// Le scénario auquel B-9 l'expose — s'ouvrir alors qu'un clavier est déjà levé
/// — est donc fermé à la source : on **abaisse le clavier** avant d'ouvrir.
/// C'est aussi ce qu'attend l'utilisateur, une pièce à lire n'ayant rien à
/// saisir. Et cela n'enlève rien à personne : le champ qui avait le focus le
/// reprend d'un tap, là où une pièce illisible ne se rattrape pas.
Future<void> _showEditiqueDocumentDialog(
  BuildContext context, {
  required String title,
  required EditiqueDocumentEvent request,
  EditiqueDocumentBloc? bloc,
  bool dispatchOnOpen = true,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _EditiqueDocumentBlocScope(
      bloc: bloc,
      request: request,
      dispatchOnOpen: dispatchOnOpen,
      child: EditiqueDocumentDialogView(
        title: title,
        // Rejoue le MÊME événement. N'est atteignable que si `state.canRetry`
        // l'autorise : sur une pièce horodatée, seule une panne réseau — donc
        // une requête jamais partie — ouvre cette porte.
        onRetry: (blocContext) =>
            blocContext.read<EditiqueDocumentBloc>().add(request),
        // Fermer la visionneuse AVANT de déconnecter : sans quoi la route de
        // dialogue resterait empilée au-dessus de la redirection vers l'écran
        // de connexion. `AuthBloc` vit au-dessus du routeur, il est donc lu
        // depuis le contexte appelant et non depuis la modale.
        onReconnect: () {
          Navigator.of(dialogContext).maybePop();
          context.read<AuthBloc>().add(const AuthLogoutRequested());
        },
      ),
    ),
  );
}

/// Fournit le BLoC de la visionneuse selon le régime de propriété (cf.
/// [_showEditiqueDocumentDialog]), et poste la demande d'émission une seule fois.
///
/// `StatefulWidget` et non un simple `BlocProvider` : le `builder` de
/// `showDialog` peut être rappelé, et poster l'événement dans un `build`
/// relancerait l'émission — ce qui, sur une pièce non archivée, brûlerait un
/// second numéro de séquence.
class _EditiqueDocumentBlocScope extends StatefulWidget {
  final EditiqueDocumentBloc? bloc;
  final EditiqueDocumentEvent request;

  /// `false` pour ROUVRIR une pièce déjà produite sans la redemander.
  ///
  /// Indispensable sur une pièce horodatée : le serveur consomme un numéro de
  /// séquence AVANT de rendre le PDF et n'archive rien. Redéclencher pour
  /// simplement réafficher ce que le BLoC détient déjà brûlerait un second
  /// numéro, et le premier serait définitivement perdu.
  final bool dispatchOnOpen;

  final Widget child;

  const _EditiqueDocumentBlocScope({
    required this.bloc,
    required this.request,
    required this.child,
    this.dispatchOnOpen = true,
  });

  @override
  State<_EditiqueDocumentBlocScope> createState() =>
      _EditiqueDocumentBlocScopeState();
}

class _EditiqueDocumentBlocScopeState
    extends State<_EditiqueDocumentBlocScope> {
  late final EditiqueDocumentBloc _bloc;

  /// Vrai quand ce widget a créé le BLoC — et doit donc le fermer. Un BLoC
  /// confié par un écran lui appartient : le fermer ici couperait la ligne du
  /// catalogue qui l'observe encore.
  late final bool _owned;

  @override
  void initState() {
    super.initState();
    _owned = widget.bloc == null;
    _bloc = widget.bloc ?? getIt<EditiqueDocumentBloc>();
    if (widget.dispatchOnOpen) _bloc.add(widget.request);
  }

  @override
  void dispose() {
    if (_owned) _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditiqueDocumentBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}

/// Contenu de la visionneuse : en-tête, corps piloté par l'état, pied d'actions.
class EditiqueDocumentDialogView extends StatelessWidget {
  /// Intitulé de la pièce affichée (« Reçu de paiement », « Relevé de compte »).
  final String title;

  /// Rejoue l'émission. Reçoit le contexte porteur du BLoC.
  ///
  /// N'est appelé que lorsque `state.canRetry` l'autorise : sur une pièce
  /// horodatée dont l'issue est inconnue, un rejeu brûlerait un second numéro
  /// de séquence côté serveur.
  final void Function(BuildContext blocContext) onRetry;

  /// Reconduit vers l'écran de connexion sur session expirée (401).
  ///
  /// Nullable pour garder la vue montable sans `AuthBloc` dans l'arbre : sans
  /// ce callback, l'anatomie 401 s'affiche sans action.
  final VoidCallback? onReconnect;

  const EditiqueDocumentDialogView({
    super.key,
    required this.title,
    required this.onRetry,
    this.onReconnect,
  });

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  Future<void> _print(BuildContext context, EditiqueDocument document) {
    return _runPlatformAction(
      context,
      () => Printing.layoutPdf(
        onLayout: (_) => document.bytes,
        name: document.fileName,
      ),
    );
  }

  Future<void> _share(BuildContext context, EditiqueDocument document) {
    return _runPlatformAction(
      context,
      () =>
          Printing.sharePdf(bytes: document.bytes, filename: document.fileName),
    );
  }

  /// Exécute une action de plateforme en rendant son échec visible.
  ///
  /// Imprimer et partager passent par le canal natif du plugin, qui peut ne pas
  /// répondre — binaire installé antérieur à l'ajout de la dépendance, ou
  /// plateforme sans service d'impression. Sans cette prise en charge, l'appui
  /// ne produit **rien du tout** : ni action, ni message, et l'exception part en
  /// erreur asynchrone non capturée.
  Future<void> _runPlatformAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final message = AppLocalizations.of(context)!.editiqueViewerActionFailed;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
    } catch (_) {
      // La pièce est intacte et toujours à l'écran : seul le geste a échoué.
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.editiqueViewerMaxWidth,
          maxHeight: maxHeight,
        ),
        child: BlocBuilder<EditiqueDocumentBloc, EditiqueDocumentState>(
          builder: (blocContext, state) {
            final document = state.document;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  title: title,
                  subtitle: document?.documentNumber == null
                      ? null
                      : l10n.editiqueViewerDocumentNumberLabel(
                          document!.documentNumber!,
                        ),
                  onClose: () => _close(context),
                ),
                const Divider(height: 1, color: AppColors.border),
                Flexible(
                  child: _Body(
                    state: state,
                    onRetry: onRetry,
                    onReconnect: onReconnect,
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                _Footer(
                  document: document,
                  onPrint: _print,
                  onShare: _share,
                  onClose: () => _close(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final EditiqueDocumentState state;
  final void Function(BuildContext blocContext) onRetry;
  final VoidCallback? onReconnect;

  const _Body({required this.state, required this.onRetry, this.onReconnect});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case EditiqueDocumentStatus.initial:
      case EditiqueDocumentStatus.loading:
        return const _LoadingBody();
      case EditiqueDocumentStatus.failure:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: EditiqueResultsErrorState(
            type: state.errorType ?? EditiqueErrorType.server,
            canRetry: state.canRetry,
            onRetry: () => onRetry(context),
            onReconnect: onReconnect,
            serverDetail: state.serverDetail,
          ),
        );
      case EditiqueDocumentStatus.success:
        return EditiqueDocumentPreview(document: state.document!);
    }
  }
}

/// Gabarit de page pendant que le serveur produit la pièce.
///
/// Le rendu serveur précède le premier octet de la réponse : cette attente est
/// réellement perceptible, elle mérite une explication et non un simple
/// tourniquet.
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.editiqueViewerLoadingTitle,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.editiqueViewerLoadingMessage,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // `Flexible` et non une hauteur sèche : la modale est déjà plafonnée
          // à 88 % de la hauteur d'écran, et l'en-tête comme le pied prennent
          // leur part. Sur une tablette paysage barres système comprises, il
          // restait moins que la hauteur du gabarit et la colonne débordait.
          // En contrainte lâche, le gabarit prend la hauteur souhaitée quand
          // elle tient, et se réduit sinon.
          const Flexible(
            child: EteeloSkeletonBox(
              height: AppDimensions.editiqueViewerSkeletonHeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final EditiqueDocument? document;
  final Future<void> Function(BuildContext context, EditiqueDocument document)
  onPrint;
  final Future<void> Function(BuildContext context, EditiqueDocument document)
  onShare;
  final VoidCallback onClose;

  const _Footer({
    required this.document,
    required this.onPrint,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ready = document;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: [
          // `fullWidth: false` obligatoire hors colonne : le thème rend les
          // boutons pleine largeur, ce qui casse une disposition en ligne.
          EteeloButton.secondary(
            label: l10n.editiqueViewerPrintLabel,
            icon: Icons.print_outlined,
            onPressed: ready == null ? null : () => onPrint(context, ready),
            fullWidth: false,
          ),
          EteeloButton.secondary(
            label: l10n.editiqueViewerShareLabel,
            icon: Icons.share_outlined,
            onPressed: ready == null ? null : () => onShare(context, ready),
            fullWidth: false,
          ),
          EteeloButton.primary(
            label: l10n.editiqueViewerCloseLabel,
            icon: Icons.check_rounded,
            onPressed: onClose,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  const _Header({required this.title, this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
