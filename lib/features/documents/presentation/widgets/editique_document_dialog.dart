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
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_preview.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/states/editique_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la visionneuse sur le reçu (RC) d'un paiement.
///
/// L'appelant reste responsable des gardes en amont : un paiement pas encore
/// synchronisé porte un uuid inconnu du serveur et produirait un 404.
Future<void> showEditiquePaymentReceiptDialog(
  BuildContext context, {
  required String paymentId,
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerReceiptTitle,
    request: EditiquePaymentReceiptRequested(paymentId: paymentId),
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
}) {
  return _showEditiqueDocumentDialog(
    context,
    title: AppLocalizations.of(context)!.editiqueViewerStatementTitle,
    request: EditiqueAccountStatementRequested(
      studentId: studentId,
      academicYearId: academicYearId,
    ),
  );
}

/// Socle commun des visionneuses.
///
/// L'émission est déclenchée à l'ouverture : le BLoC est créé pour cette modale
/// et fermé avec elle, donc une seule pièce est vivante en mémoire à la fois.
///
/// Hors ligne, aucune pièce ne peut être produite — le repository le tranche en
/// pré-garde et la modale affiche l'anatomie réseau sans attente.
Future<void> _showEditiqueDocumentDialog(
  BuildContext context, {
  required String title,
  required EditiqueDocumentEvent request,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => BlocProvider<EditiqueDocumentBloc>(
      create: (_) => getIt<EditiqueDocumentBloc>()..add(request),
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
