import 'dart:convert';

/// Ce qu'un onglet annonce aux autres de sa session.
sealed class TabSessionMessage {
  const TabSessionMessage();

  String encode();

  /// `null` pour un message illisible — d'une autre version de l'application,
  /// par exemple : on n'en conclut rien.
  static TabSessionMessage? decode(String raw) {
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    return switch (json['type']) {
      'signedOut' => const TabSignedOut(),
      'signedIn' => switch (json['userId']) {
        final String userId => TabSignedIn(userId),
        _ => null,
      },
      _ => null,
    };
  }
}

/// Un agent s'est connecté dans un autre onglet : le stockage du navigateur,
/// partagé, porte désormais SA session.
class TabSignedIn extends TabSessionMessage {
  final String userId;

  const TabSignedIn(this.userId);

  @override
  String encode() => jsonEncode({'type': 'signedIn', 'userId': userId});
}

/// La session a pris fin dans un autre onglet.
class TabSignedOut extends TabSessionMessage {
  const TabSignedOut();

  @override
  String encode() => jsonEncode({'type': 'signedOut'});
}
