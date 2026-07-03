import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultat_focus_args.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_support.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_bulletin_domaine.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_bulletin_officiel_card.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_focus_header.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_focus_matieres.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_focus_progression.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_focus_skeleton.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_focus_synthese.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_card.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vue focus d'un élève (spec §6-9). Fournit son propre [ResultatFocusBloc]
/// (patron « le détail possède son BLoC ») et le déclenche au montage.
class ResultatFocusPage extends StatelessWidget {
  final ResultatFocusArgs args;
  final VoidCallback onBack;

  const ResultatFocusPage({
    super.key,
    required this.args,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResultatFocusBloc>(
      create: (_) => GetIt.instance<ResultatFocusBloc>()
        ..add(
          ResultatFocusRequested(
            classroomId: args.classroomId,
            periodeScolaireId: args.periodeScolaireId,
            studentId: args.studentId,
          ),
        ),
      child: _ResultatFocusView(args: args, onBack: onBack),
    );
  }
}

class _ResultatFocusView extends StatelessWidget {
  final ResultatFocusArgs args;
  final VoidCallback onBack;

  const _ResultatFocusView({required this.args, required this.onBack});

  void _retry(BuildContext context) {
    context.read<ResultatFocusBloc>().add(
      ResultatFocusRequested(
        classroomId: args.classroomId,
        periodeScolaireId: args.periodeScolaireId,
        studentId: args.studentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: BlocBuilder<ResultatFocusBloc, ResultatFocusState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.focus != curr.focus ||
            prev.errorType != curr.errorType,
        builder: (context, state) {
          final entete = state.focus?.entete;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResultatFocusHeader(
                prenom: entete?.prenom ?? args.prenom,
                nom: entete?.nom ?? args.nom,
                postnom: entete?.postnom ?? args.postnom,
                genre: entete?.genre ?? args.genre,
                classroomLabel: args.classroomLabel,
                studentId: args.studentId,
                moyenneAnnuelle: entete?.moyenneAnnuelle,
                rang: entete?.rang,
                nbClasses: entete?.nbClasses ?? 0,
                onBack: onBack,
              ),
              const SizedBox(height: AppSpacing.xl),
              _body(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ResultatFocusState state) {
    return switch (state.status) {
      ResultatFocusStatus.initial ||
      ResultatFocusStatus.loading => const ResultatFocusSkeleton(),
      ResultatFocusStatus.failure => ResultatsResultsErrorState(
        type: state.errorType,
        onRetry: () => _retry(context),
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        onContactAdmin: resultatsContactSupport,
      ),
      ResultatFocusStatus.success => _success(context, state.focus!),
    };
  }

  Widget _success(BuildContext context, ResultatFocus focus) {
    final bulletin = focus.bulletinParDomaine;
    final sections = <Widget>[
      ResultatFocusProgression(
        progression: focus.progression,
        deltaPts: focus.deltaPts,
        seuil: ResultatBulletinDomaine.defautSeuil,
      ),
      if (focus.topMatieres.isNotEmpty || focus.bottomMatieres.isNotEmpty)
        ResultatFocusMatieres(
          topMatieres: focus.topMatieres,
          bottomMatieres: focus.bottomMatieres,
        ),
      const ResultatBulletinOfficielCard(),
      if (bulletin != null)
        ResultatBulletinDomaine(
          bulletin: bulletin,
          periodeLongLabel: args.periodeLabel,
        )
      else
        const _NonClasseNote(),
      ResultatFocusSynthese(synthese: focus.synthese),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          sections[i],
        ],
      ],
    );
  }
}

class _NonClasseNote extends StatelessWidget {
  const _NonClasseNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResultatsCard(
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.resultatsFocusNoBulletin,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
