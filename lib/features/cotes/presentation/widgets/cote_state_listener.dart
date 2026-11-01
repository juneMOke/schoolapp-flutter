import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';

/// Écoute les états avec le précédent en main, ce que `BlocListener` ne donne
/// qu'à son `listenWhen`.
class CoteStateListener extends StatefulWidget {
  final void Function(BuildContext, CoteSaisieState, CoteSaisieState) onChanged;
  final Widget child;

  const CoteStateListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  @override
  State<CoteStateListener> createState() => CoteStateListenerState();
}

class CoteStateListenerState extends State<CoteStateListener> {
  late CoteSaisieState _previous = context.read<CoteSaisieBloc>().state;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoteSaisieBloc, CoteSaisieState>(
      listener: (context, state) {
        final previous = _previous;
        _previous = state;
        widget.onChanged(context, previous, state);
      },
      child: widget.child,
    );
  }
}
