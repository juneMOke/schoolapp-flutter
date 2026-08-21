import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bouton principal d'une ligne de document, avec son état local.
///
/// L'état `busy` vient du BLoC **de cette ligne** : une émission en cours sur le
/// relevé n'éteint pas l'attestation d'à côté. Le verrou anti-double-envoi vit
/// dans le BLoC lui-même — ici on ne fait que le refléter.
///
/// Émettre une pièce numérotée avance une séquence comptable côté serveur :
/// c'est une écriture, donc gelée en session lecture seule au même titre qu'un
/// encaissement.
class DocumentsCatalogActionButton extends StatelessWidget {
  final DocumentsCatalogAction action;
  final VoidCallback onPressed;

  const DocumentsCatalogActionButton({
    super.key,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EditiqueDocumentBloc, EditiqueDocumentState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final isBusy = state.status == EditiqueDocumentStatus.loading;

        final button = EteeloButton.primary(
          label: isBusy ? l10n.documentsActionBusyLabel : _label(l10n),
          icon: isBusy ? null : _icon,
          onPressed: (action.isEnabled && !isBusy) ? onPressed : null,
          fullWidth: false,
        );

        // La garde de session gèle ce qui **produit** une pièce côté serveur.
        // Ressortir une copie locale n'écrit rien, ne consomme aucun numéro et
        // n'exige aucun jeton : la geler priverait le guichet de ses documents
        // au moment précis où il en a le plus besoin — une session en lecture
        // seule est une session hors ligne depuis trois semaines.
        // Même partage que ci-dessus pour la permission : ressortir une copie
        // déjà émise relève de `editique.read`, qui a ouvert le catalogue.
        // Produire une pièce neuve exige `editique.write`.
        return action.isRestitution
            ? button
            : PermissionGate(
                requires: const [Perm.editiqueWrite],
                child: SessionWriteGate(child: button),
              );
      },
    );
  }

  String _label(AppLocalizations l10n) => switch (action.kind) {
    DocumentsCatalogActionKind.emit => l10n.documentsActionEmitLabel,
    DocumentsCatalogActionKind.consult => l10n.documentsActionConsultLabel,
    DocumentsCatalogActionKind.generate => l10n.documentsActionGenerateLabel,
    // Le libellé d'une action éteinte reste celui qu'elle proposerait : c'est le
    // message sous la ligne qui explique, pas le bouton qui se renomme.
    DocumentsCatalogActionKind.disabled => l10n.documentsActionEmitLabel,
  };

  IconData get _icon => switch (action.kind) {
    DocumentsCatalogActionKind.consult => Icons.visibility_outlined,
    DocumentsCatalogActionKind.generate => Icons.refresh_rounded,
    _ => Icons.approval_outlined,
  };
}

/// Message d'accompagnement d'une ligne éteinte, ou d'une ligne en erreur.
///
/// `null` quand il n'y a rien à dire — notamment pendant la résolution des
/// gardes : on n'annonce jamais une raison qu'on ne connaît pas encore.
class DocumentsCatalogRowNotice extends StatelessWidget {
  final DocumentsCatalogAction action;

  const DocumentsCatalogRowNotice({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EditiqueDocumentBloc, EditiqueDocumentState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.serverDetail != curr.serverDetail,
      builder: (context, state) {
        // L'échec reste dans la ligne : un service qui tombe pour un document
        // ne fait pas basculer la page entière en erreur.
        if (state.status == EditiqueDocumentStatus.failure) {
          return _Notice(
            text: state.serverDetail ?? l10n.documentsActionFailedNotice,
            tone: _NoticeTone.error,
          );
        }

        // Le retrait d'une pièce se dit même quand la ligne propose quelque
        // chose : c'est le seul endroit où le guichet apprend pourquoi le
        // papier qu'on lui présente n'a plus cours. Il passe donc AVANT les
        // blocages conjoncturels, qui expliquent l'action et non la pièce.
        final cancelled = _cancelledMessage(context, l10n);
        if (cancelled != null) {
          return _Notice(text: cancelled, tone: _NoticeTone.warning);
        }

        final message = _blockMessage(l10n);
        if (message == null) return const SizedBox.shrink();
        return _Notice(text: message, tone: _NoticeTone.muted);
      },
    );
  }

  /// Ce que l'école a retiré, et pourquoi quand elle l'a dit.
  ///
  /// Le motif vient du **serveur** — texte libre saisi par un agent. Il
  /// s'affiche tel quel, sans traduction ni reformulation, et son absence ne se
  /// comble pas : une pièce peut être retirée sans motif, et inventer la phrase
  /// manquante ferait dire à l'application ce qu'elle ne sait pas.
  String? _cancelledMessage(BuildContext context, AppLocalizations l10n) {
    final cancelled = action.cancelledPiece;
    final cancelledAt = cancelled?.cancelledAt;
    if (cancelled == null || cancelledAt == null) return null;

    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.fromMillisecondsSinceEpoch(cancelledAt));
    final reason = cancelled.cancellationReason?.trim();

    return (reason == null || reason.isEmpty)
        ? l10n.documentsCancelledNotice(date)
        : l10n.documentsCancelledWithReasonNotice(date, reason);
  }

  /// Message d'un blocage **conjoncturel** — quelque chose qui changera.
  ///
  /// Deux motifs n'en ont pas, et c'est voulu : `resolving`, parce qu'on ne dit
  /// pas une raison qu'on ne connaît pas encore ; et `issuedFromBilling`, parce
  /// que ce n'est pas une circonstance mais une **propriété permanente** du
  /// reçu — elle est déjà portée par la phrase d'aide de la ligne, et la répéter
  /// ferait dire deux fois la même chose à deux endroits.
  String? _blockMessage(AppLocalizations l10n) => switch (action.reason) {
    DocumentsCatalogBlockReason.pendingSync =>
      l10n.documentsBlockedPendingSyncNotice,
    DocumentsCatalogBlockReason.enrollmentPendingSync =>
      l10n.documentsBlockedEnrollmentPendingSyncNotice,
    DocumentsCatalogBlockReason.missingEnrollmentRef =>
      l10n.documentsBlockedMissingEnrollmentNotice,
    DocumentsCatalogBlockReason.enrollmentUnreadable =>
      l10n.documentsBlockedEnrollmentUnreadableNotice,
    DocumentsCatalogBlockReason.offline => l10n.documentsBlockedOfflineNotice,
    DocumentsCatalogBlockReason.issuedFromBilling ||
    DocumentsCatalogBlockReason.resolving ||
    null => null,
  };
}

/// Trois tons, trois natures de message : ce qui explique la ligne (`muted`),
/// ce qui a échoué (`error`), et ce que l'établissement a retiré (`warning`) —
/// un fait durable, pas une panne, et pas une simple circonstance.
enum _NoticeTone { muted, error, warning }

class _Notice extends StatelessWidget {
  final String text;
  final _NoticeTone tone;

  const _Notice({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    // L'information n'est jamais portée par la seule couleur : le ton
    // d'avertissement double son rouge-orangé d'une icône, comme le badge de
    // nature le fait à côté.
    final isWarning = tone == _NoticeTone.warning;
    final label = Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: switch (tone) {
          _NoticeTone.error => AppColors.error,
          _NoticeTone.warning => AppColors.warning,
          _NoticeTone.muted => AppColors.textMuted,
        },
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
      child: isWarning
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Expanded(child: label),
              ],
            )
          : label,
    );
  }
}
