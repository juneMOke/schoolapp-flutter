import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_detail_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_saisie_page.dart';

/// Niveau « évaluation » de la coquille Cours (spec § Anatomie) : le détail,
/// et sous lui la saisie des notes. Revenir de la saisie remonte le détail,
/// qui relit son état en local.
class EvalFlowPage extends StatefulWidget {
  final EvalDetailArgs args;

  /// Retour au détail du cours.
  final VoidCallback onBack;

  const EvalFlowPage({super.key, required this.args, required this.onBack});

  @override
  State<EvalFlowPage> createState() => _EvalFlowPageState();
}

class _EvalFlowPageState extends State<EvalFlowPage> {
  bool _inSaisie = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: _inSaisie
          ? EvalSaisiePage(
              key: const ValueKey<String>('eval-saisie'),
              args: widget.args,
              onBack: () => setState(() => _inSaisie = false),
            )
          : EvalDetailPage(
              key: const ValueKey<String>('eval-detail'),
              args: widget.args,
              onBack: widget.onBack,
              onOpenSaisie: () => setState(() => _inSaisie = true),
            ),
    );
  }
}
