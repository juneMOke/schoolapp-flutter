import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/publication_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rend l'issue d'une publication : envoyée, retirée, ou pourquoi elle n'a
/// pas abouti.
class PublicationFeedback extends StatelessWidget {
  final Widget child;

  const PublicationFeedback({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PublicationBloc, PublicationState>(
      listenWhen: (prev, curr) =>
          prev.outcome != curr.outcome &&
          curr.outcome != PublicationOutcome.none,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final kind = state.outcomeKind;
        final label = kind == null ? '' : publicationKindLabel(l10n, kind);
        switch (state.outcome) {
          case PublicationOutcome.published:
            AppSnackBar.showSuccess(context, l10n.publicationSentToast(label));
          case PublicationOutcome.withdrawn:
            AppSnackBar.showSuccess(
              context,
              l10n.publicationWithdrawnToast(label),
            );
          case PublicationOutcome.failed:
            AppSnackBar.showError(
              context,
              publicationFailureMessage(l10n, state.failure),
            );
          case PublicationOutcome.none:
            break;
        }
      },
      child: child,
    );
  }
}
