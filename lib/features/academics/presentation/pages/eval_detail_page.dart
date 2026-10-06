import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/helpers/support_contact.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_title.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/common/eval_sticky_bottom_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_back_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_summary_card.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval_detail/eval_detail_action_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/eval_saisie_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';

/// Page de pilotage d'une évaluation (spec S1) : en-tête résumé, puis le
/// sujet, la copie et la publication, et la barre d'actions collante. La
/// saisie des notes a sa propre page ([onOpenSaisie]).
class EvalDetailPage extends StatelessWidget {
  final EvalDetailArgs args;
  final VoidCallback onBack;
  final VoidCallback onOpenSaisie;

  const EvalDetailPage({
    super.key,
    required this.args,
    required this.onBack,
    required this.onOpenSaisie,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EvalDetailBloc>(
      create: (_) =>
          GetIt.instance<EvalDetailBloc>()
            ..add(EvalDetailRequested(args.eval.id)),
      child: _EvalDetailView(
        args: args,
        onBack: onBack,
        onOpenSaisie: onOpenSaisie,
      ),
    );
  }
}

class _EvalDetailView extends StatelessWidget {
  final EvalDetailArgs args;
  final VoidCallback onBack;
  final VoidCallback onOpenSaisie;

  const _EvalDetailView({
    required this.args,
    required this.onBack,
    required this.onOpenSaisie,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvalDetailBloc, EvalDetailState>(
      builder: (context, state) {
        final ready = state.status == EvalDetailStatus.ready;
        final eval = ready
            ? args.eval.withProgress(
                saisies: state.progress.saisies,
                total: state.progress.total,
              )
            : args.eval;
        return AppPageBackground(
          scrollable: true,
          bottomNavigationBar: ready
              ? EvalStickyBottomBar(
                  child: EvalDetailActionBar(
                    progress: state.progress,
                    onSaisir: onOpenSaisie,
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EvalBackBar(
                brancheNom: args.brancheNom,
                classroomName: args.classroomName,
                evalName: evalDisplayName(context, args.eval),
                onBack: onBack,
              ),
              const SizedBox(height: AppSpacing.lg),
              EvalSummaryCard(
                args: args.copyWith(eval: eval),
                dureeMinutes: state.sujet.cadre.dureeMinutes,
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                alignment: Alignment.topCenter,
                child: _body(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, EvalDetailState state) =>
      switch (state.status) {
        EvalDetailStatus.loading => const EteeloListSkeleton(rowCount: 3),
        EvalDetailStatus.failure => EvalSaisieResultsErrorState.failure(
          failure: state.failure!,
          onRetry: () => context.read<EvalDetailBloc>().add(
            EvalDetailRequested(args.eval.id),
          ),
          onReconnect: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          onContactAdmin: contactSupport,
        ),
        EvalDetailStatus.ready => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        ),
      };
}
