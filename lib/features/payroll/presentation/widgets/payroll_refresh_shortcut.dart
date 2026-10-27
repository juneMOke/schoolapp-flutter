import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';

/// F5 / Ctrl+R sur une page de la paie : tire les flux puis relit la
/// tablette — le geste du bouton « Synchroniser puis revoir », sans
/// recharger la page web.
class PayrollRefreshShortcut extends StatelessWidget {
  final Widget child;

  const PayrollRefreshShortcut({super.key, required this.child});

  @override
  Widget build(BuildContext context) => PageActionShortcut(
    action: PageAction.refresh,
    onInvoke: () => unawaited(context.read<PayrollCubit>().syncAndRefresh()),
    child: child,
  );
}
