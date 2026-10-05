import 'package:flutter/foundation.dart';

/// Le poste sait-il poser une photo ? Pas le web : le magasin chiffré repose
/// sur `dart:io` et rend chaque prise en échec. Les entrées s'y masquent, la
/// photo descendue reste affichée.
bool get photoCaptureSupported => !kIsWeb;
