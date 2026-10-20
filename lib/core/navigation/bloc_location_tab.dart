import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_tab_sync.dart';

/// [LocationTabSync] pour un onglet tenu par un bloc [B] : [tabOf] le lit,
/// [select] le change. Seul le changement d'onglet reconstruit le lien.
class BlocLocationTab<B extends StateStreamable<S>, S, T extends Enum>
    extends StatelessWidget {
  final List<T> values;
  final T Function(S state) tabOf;
  final void Function(B bloc, T tab) select;
  final Widget child;

  const BlocLocationTab({
    super.key,
    required this.values,
    required this.tabOf,
    required this.select,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => BlocSelector<B, S, T>(
    selector: tabOf,
    builder: (context, tab) => LocationTabSync<T>(
      values: values,
      current: tab,
      onLocationTab: (tab) => select(context.read<B>(), tab),
      child: child,
    ),
  );
}
