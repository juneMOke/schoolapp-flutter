import 'package:flutter/foundation.dart' show listEquals;
import 'package:school_app_flutter/features/home/data/sidebar_preference_store.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell_location_sync.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell_tab_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_layout.dart';

class HomePage extends StatelessWidget {
  /// L'écran porté par l'adresse (`/home/{sousMenu}`) ; `null` : l'Accueil.
  final String? subMenuId;

  const HomePage({super.key, this.subMenuId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Lu ici, pas dans `create` : un fournisseur ne s'abonne pas à la taille.
    final sidebarExpanded =
        MediaQuery.sizeOf(context).width >=
        AppBreakpoints.sidebarExpandedDefaultMin;
    return BlocProvider(
      create: (context) {
        final bloc = NavigationBloc(
          l10n,
          permissions: context.read<AuthBloc>().state.permissions,
          sidebarExpanded: sidebarExpanded,
          sidebarPreference: getIt.isRegistered<SidebarPreferenceStore>()
              ? getIt<SidebarPreferenceStore>()
              : null,
        );
        ShellLocationSync.select(bloc, subMenuId?.trim(), l10n);
        return bloc;
      },
      // Le refresh est le seul canal par lequel un changement de droits
      // redescend (ADR-014 §4), et il se produit en arrière-plan : sans ce
      // relais, l'arborescence resterait celle du login jusqu'au prochain
      // démarrage. `listenWhen` sur l'ensemble seul — le reste des transitions
      // d'auth n'a pas à reconstruire le menu.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            !listEquals(previous.permissions, current.permissions),
        listener: (context, state) => context.read<NavigationBloc>().add(
          NavigationPermissionsChanged(
            l10n: l10n,
            permissions: state.permissions,
          ),
        ),
        child: ShellLocationSync(
          subMenuId: subMenuId,
          child: const ShellTabTitle(child: ShellLayout()),
        ),
      ),
    );
  }
}
