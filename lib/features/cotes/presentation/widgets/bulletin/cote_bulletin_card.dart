import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_footer.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_header.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_legend.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';

/// Le bulletin de l'élève courant. La grille n'est reconstruite qu'au changement
/// d'élève ou de colonnes : une frappe ne touche que ses cellules et ses totaux.
class CoteBulletinCard extends StatefulWidget {
  final String classroomName;

  /// Appelé à chaque passage à un autre élève (la frappe en attente part).
  final VoidCallback? onStudentChanged;

  const CoteBulletinCard({
    super.key,
    required this.classroomName,
    this.onStudentChanged,
  });

  @override
  State<CoteBulletinCard> createState() => _CoteBulletinCardState();
}

class _CoteBulletinCardState extends State<CoteBulletinCard> {
  GlobalKey<CoteGridState> _gridKey = GlobalKey<CoteGridState>();
  CoteMove _enterMove = CoteMove.down;
  bool _focusAfterStep = false;

  void _stepped() {
    _focusAfterStep = true;
    widget.onStudentChanged?.call();
  }

  void _step(int delta) {
    context.read<CoteSaisieBloc>().add(CoteStudentStepped(delta));
    _stepped();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
            _step(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
            _step(1),
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.border),
        ),
        child: BlocConsumer<CoteSaisieBloc, CoteSaisieState>(
          listenWhen: (previous, current) => _gridChanged(previous, current),
          listener: (context, state) {
            _gridKey = GlobalKey<CoteGridState>();
            if (!_focusAfterStep) return;
            _focusAfterStep = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _gridKey.currentState?.focusFirstEmpty();
            });
          },
          buildWhen: _gridChanged,
          builder: (context, state) {
            if (state is! CoteSaisieReady) return const SizedBox.shrink();
            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CoteBulletinHeader(
                      classroomName: widget.classroomName,
                      onStepped: _stepped,
                    ),
                    CoteBulletinLegend(
                      columns: state.columns,
                      enterMove: _enterMove,
                      showKeyboardHelp:
                          constraints.maxWidth >=
                          AppBreakpoints.coteGridPhoneMax,
                      onToggleEnter: () => setState(
                        () => _enterMove = _enterMove == CoteMove.down
                            ? CoteMove.right
                            : CoteMove.down,
                      ),
                    ),
                    CoteGrid(key: _gridKey, enterMove: _enterMove),
                    CoteBulletinFooter(onStepped: _stepped),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Un autre élève ou d'autres colonnes : la grille repart de zéro.
  static bool _gridChanged(CoteSaisieState previous, CoteSaisieState current) {
    if (previous is! CoteSaisieReady || current is! CoteSaisieReady) {
      return true;
    }
    return previous.currentId != current.currentId ||
        previous.columns != current.columns;
  }
}
