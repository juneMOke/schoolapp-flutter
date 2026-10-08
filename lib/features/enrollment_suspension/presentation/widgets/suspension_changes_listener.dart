import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';

/// Rappelle [onChanged] chaque fois qu'une désactivation change sur ce poste
/// (geste local, accusé, refus, descente du flux) : les écrans qui montrent
/// l'état se relisent, et un geste fait sur l'un se voit sur les autres.
class SuspensionChangesListener extends StatefulWidget {
  final VoidCallback onChanged;
  final Widget child;

  const SuspensionChangesListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  @override
  State<SuspensionChangesListener> createState() =>
      _SuspensionChangesListenerState();
}

class _SuspensionChangesListenerState extends State<SuspensionChangesListener> {
  StreamSubscription<Set<String>>? _subscription;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<LoadOpenSuspensionsUseCase>()) {
      _subscription = getIt<LoadOpenSuspensionsUseCase>().changes.listen(
        (_) => widget.onChanged(),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
