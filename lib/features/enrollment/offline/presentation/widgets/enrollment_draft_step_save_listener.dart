import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';

/// Écouteur partagé du parcours NEW offline-first : chaque étape du wizard
/// l'enveloppe pour réagir au résultat de son écriture locale sur le
/// [EnrollmentOfflineBloc], sans dupliquer la plomberie BlocListener.
///
/// Seuls les états terminaux d'une écriture initiée PAR l'étape courante sont
/// pris en compte ([isAwaiting]) :
///  - [EnrollmentDraftStepSaved] → [onSaved] (dé-dirty + ré-hydratation locale) ;
///  - [EnrollmentDraftError] → [onError] (toast d'échec + déverrouillage).
///
/// Les états transitoires de la ré-hydratation ([EnrollmentDraftSaving] /
/// [EnrollmentDraftDetailLoaded]) sont ignorés (l'agrégat est reconstruit par la
/// page hôte). Désactivé ([enabled] = false) pour les parcours online RE/PRE.
class EnrollmentDraftStepSaveListener extends StatelessWidget {
  final bool enabled;
  final bool Function() isAwaiting;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;
  final Widget child;

  const EnrollmentDraftStepSaveListener({
    super.key,
    required this.enabled,
    required this.isAwaiting,
    required this.onSaved,
    required this.onError,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      listenWhen: (previous, current) =>
          previous != current &&
          (current is EnrollmentDraftStepSaved ||
              current is EnrollmentDraftError),
      listener: (context, state) {
        if (!isAwaiting()) return;
        if (state is EnrollmentDraftStepSaved) {
          onSaved();
        } else if (state is EnrollmentDraftError) {
          onError(state.message);
        }
      },
      child: child,
    );
  }
}
