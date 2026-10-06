import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_detail_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_saisie_page.dart';

/// Niveau « évaluation » de la coquille Cours (spec § Anatomie) : le détail,
/// et au-dessus de lui la saisie des notes. Revenir de la saisie retrouve le
/// détail tel qu'il était, qui relit son état en local.
class EvalFlowPage extends StatefulWidget {
  final EvalDetailArgs args;

  /// Retour au détail du cours.
  final VoidCallback onBack;

  const EvalFlowPage({super.key, required this.args, required this.onBack});

  @override
  State<EvalFlowPage> createState() => _EvalFlowPageState();
}

class _EvalFlowPageState extends State<EvalFlowPage> {
  /// En-tête courant : le détail le relit (maximum ajusté) avant d'ouvrir la
  /// saisie, et le retrouve au retour.
  late EvalDetailArgs _args = widget.args;
  bool _inSaisie = false;

  /// Incrémenté au retour de la saisie : le détail, resté monté, se relit.
  int _returns = 0;

  @override
  Widget build(BuildContext context) {
    // Le détail reste monté sous la saisie : au retour, il garde ses sections
    // dépliées et ses options de copie, et se relit sans squelette.
    return IndexedStack(
      index: _inSaisie ? 1 : 0,
      children: [
        EvalDetailPage(
          args: _args,
          refreshToken: _returns,
          onBack: widget.onBack,
          onOpenSaisie: (args) => setState(() {
            _args = args;
            _inSaisie = true;
          }),
        ),
        if (_inSaisie)
          EvalSaisiePage(
            args: _args,
            onBack: () => setState(() {
              _inSaisie = false;
              _returns++;
            }),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
