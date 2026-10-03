import 'package:flutter/foundation.dart';

/// Poste de bureau (Windows, Linux) : ni SQLCipher natif, ni Bluetooth
/// Classic, ni prise de vue.
///
/// Lu sur `defaultTargetPlatform`, et non sur `dart:io` : sous `flutter test`
/// il vaut Android quel que soit l'hôte — la suite, lancée sur Linux, garde
/// donc le parcours de la tablette — et `debugDefaultTargetPlatformOverride`
/// suffit à exercer celui du bureau.
///
/// macOS n'en fait pas partie : `sqflite_sqlcipher` y a une implémentation,
/// et le poste n'est pas une cible livrée.
bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);
