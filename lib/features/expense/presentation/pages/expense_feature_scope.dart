import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/sync_expense_pulls_use_case.dart';

/// Scope des deux écrans des dépenses : il hydrate le registre et le taux du
/// jour **au montage**, par le coordinateur (ADR-015 F6).
///
/// Il ne fournit aucun bloc : chaque écran crée son cubit, et la période se
/// partage par `ExpensePeriodMemory`. Le second déclencheur reste le cycle
/// complet du coordinateur — une tablette posée sur le Wi-Fi de l'école ne
/// verrait aucun retour « en ligne » de la journée.
class ExpenseFeatureScope extends StatefulWidget {
  final Widget child;

  const ExpenseFeatureScope({super.key, required this.child});

  @override
  State<ExpenseFeatureScope> createState() => _ExpenseFeatureScopeState();
}

class _ExpenseFeatureScopeState extends State<ExpenseFeatureScope> {
  @override
  void initState() {
    super.initState();
    unawaited(GetIt.instance<SyncExpensePullsUseCase>()());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
