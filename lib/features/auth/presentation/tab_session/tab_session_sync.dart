import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/web/tab_channel/tab_channel.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/tab_session/tab_session_message.dart';

/// Tient d'accord les onglets d'un même navigateur, qui partagent le
/// stockage de la session.
///
/// - Cet onglet se connecte ou se déconnecte : il l'annonce.
/// - Un autre se déconnecte, ou y connecte un AUTRE agent : cet onglet revient
///   à la connexion ([AuthSessionEndedElsewhere]) — sans quoi il garderait à
///   l'écran les données de la session précédente, en signant ses requêtes
///   avec le jeton du nouvel agent.
class TabSessionSync extends StatefulWidget {
  final Widget child;

  /// Le canal ; celui de la plateforme par défaut (muet hors du web).
  final TabChannel Function() openChannel;

  const TabSessionSync({
    super.key,
    required this.child,
    this.openChannel = _defaultChannel,
  });

  static TabChannel _defaultChannel() => TabChannel('eteelo-session');

  @override
  State<TabSessionSync> createState() => _TabSessionSyncState();
}

class _TabSessionSyncState extends State<TabSessionSync> {
  late final TabChannel _channel = widget.openChannel();
  StreamSubscription<String>? _subscription;

  /// Cet onglet a eu une session : seule sa fin s'annonce. Un onglet qui
  /// s'ouvre sans session (rien dans le stockage) n'a rien à dire aux autres.
  bool _hadSession = false;

  /// La fin de session vient d'un autre onglet : ne pas la renvoyer — elle
  /// déconnecterait l'onglet où un autre agent vient de se connecter.
  bool _endedElsewhere = false;

  @override
  void initState() {
    super.initState();
    _subscription = _channel.messages.listen(_onMessage);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _channel.close();
    super.dispose();
  }

  void _onMessage(String raw) {
    final message = TabSessionMessage.decode(raw);
    if (!mounted || message == null) return;
    final auth = context.read<AuthBloc>();
    final current = auth.state;
    if (current.status != AuthStatus.authenticated) return;
    final endsHere = switch (message) {
      TabSignedOut() => true,
      TabSignedIn(:final userId) => userId != current.user?.id,
    };
    if (!endsHere) return;
    _endedElsewhere = true;
    auth.add(const AuthSessionEndedElsewhere());
  }

  void _announce(BuildContext context, AuthState state) {
    final user = state.user;
    if (state.status == AuthStatus.authenticated && user != null) {
      _hadSession = true;
      _endedElsewhere = false;
      _channel.post(TabSignedIn(user.id).encode());
      return;
    }
    if (state.status != AuthStatus.unauthenticated || !_hadSession) return;
    _hadSession = false;
    if (_endedElsewhere) {
      _endedElsewhere = false;
      return;
    }
    _channel.post(const TabSignedOut().encode());
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    // Le changement de statut seul : un rafraîchissement des droits ne
    // s'annonce pas.
    listenWhen: (previous, current) =>
        previous.status != current.status &&
        (current.status == AuthStatus.authenticated ||
            current.status == AuthStatus.unauthenticated),
    listener: _announce,
    child: widget.child,
  );
}
