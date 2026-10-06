import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet_codes.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

String _date(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatCompactDate(date.toLocal());

/// « Publié le 06/10/2026 · màj 07/10/2026 ».
String publicationEtatLabel(BuildContext context, PublicationEtat etat) {
  final l10n = AppLocalizations.of(context)!;
  final published = l10n.publicationPublishedOn(
    _date(context, etat.publishedAt),
  );
  final updated = etat.updatedAt;
  return updated == null
      ? published
      : l10n.publicationUpdatedOn(published, _date(context, updated));
}

/// Nom d'un élément publiable.
String publicationKindLabel(AppLocalizations l10n, PublicationKind kind) =>
    switch (kind) {
      PublicationKind.sujet => l10n.publicationKindSujet,
      PublicationKind.corrige => l10n.publicationKindCorrige,
      PublicationKind.notes => l10n.publicationKindNotes,
    };

/// Pourquoi une publication n'a pas abouti.
String publicationFailureMessage(AppLocalizations l10n, Failure? failure) =>
    switch (failure) {
      PublicationRefusedFailure(
        code: EvaluationSujetCodes.evaluationIncomplete,
        :final saisies,
        :final effectif,
      ) =>
        saisies != null && effectif != null
            ? l10n.publicationRefusedIncompleteCount(saisies, effectif)
            : l10n.publicationRefusedIncomplete,
      PublicationRefusedFailure(code: EvaluationSujetCodes.sujetEmpty) =>
        l10n.publicationRefusedEmpty,
      PublicationRefusedFailure(
        code: EvaluationSujetCodes.sujetNotPublishable,
      ) =>
        l10n.publicationSujetInClass,
      PublicationRefusedFailure(code: EvaluationSujetCodes.coursNotOwned) ||
      UnauthorizedFailure() => l10n.publicationRefusedNotOwned,
      NetworkFailure() => l10n.publicationOffline,
      _ => l10n.publicationFailed,
    };

/// Ce qui retient une publication sur la tablette ; `null` si rien.
String? publicationPendingReason(
  AppLocalizations l10n,
  PublicationContext context,
) => context.anythingPending ? l10n.publicationPendingWrites : null;
