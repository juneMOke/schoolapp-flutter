import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/device/pointer_kind_scope.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Actualiser », dans l'en-tête d'un écran de la trésorerie : l'équivalent
/// visible de F5 pour qui tient une souris. Au doigt, il disparaît là où la
/// page se tire (tablette, téléphone) ; un écran tactile de bureau, où rien
/// ne se tire, le garde.
///
/// Rien hors d'un [TreasuryRefreshScope].
class TreasuryRefreshButton extends StatefulWidget {
  const TreasuryRefreshButton({super.key});

  /// Les actions d'un `EteeloPageHeader` : le bouton à la souris, rien au
  /// doigt — un enfant vide ouvrirait une rangée de plus dans le `Wrap` de
  /// l'en-tête sur un téléphone.
  static List<Widget> headerActions(BuildContext context) =>
      TreasuryRefreshScope.maybeOf(context) != null && _offered(context)
      ? const [TreasuryRefreshButton()]
      : const [];

  /// À la souris, ou là où la page ne se tire pas.
  static bool _offered(BuildContext context) =>
      PointerKindScope.usesMouseOf(context) ||
      !TreasuryRefreshScope.pullsToRefresh;

  @override
  State<TreasuryRefreshButton> createState() => _TreasuryRefreshButtonState();
}

class _TreasuryRefreshButtonState extends State<TreasuryRefreshButton> {
  var _busy = false;

  Future<void> _run(Future<void> Function() refresh) async {
    setState(() => _busy = true);
    try {
      await refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refresh = TreasuryRefreshScope.maybeOf(context);
    if (refresh == null || !TreasuryRefreshButton._offered(context)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.treasuryRefreshTooltip,
      child: EteeloButton.ghost(
        label: l10n.refresh,
        icon: Icons.refresh,
        fullWidth: false,
        onPressed: _busy ? null : () => _run(refresh),
      ),
    );
  }
}
