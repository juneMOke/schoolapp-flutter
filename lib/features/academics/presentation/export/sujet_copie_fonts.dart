import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Polices de la copie : Inter pour le corps, Lora pour le titre et les
/// numéros. Embarquées, et non les polices intégrées au format : celles-ci
/// s'arrêtent au Latin-1, et un sujet porte des formules (H₂SO₄, ≥, x²).
///
/// Chargées une fois par session — une copie se réaffiche souvent.
class SujetCopieFonts {
  final pw.Font body;
  final pw.Font bodyBold;
  final pw.Font title;
  final pw.Font italic;

  const SujetCopieFonts({
    required this.body,
    required this.bodyBold,
    required this.title,
    required this.italic,
  });

  static Future<SujetCopieFonts>? _loaded;

  /// Un échec n'est pas retenu : le prochain appel recharge.
  static Future<SujetCopieFonts> load() =>
      _loaded ??= _load().catchError((Object error) {
        _loaded = null;
        throw error;
      });

  static Future<SujetCopieFonts> _load() async {
    Future<pw.Font> font(String path) async =>
        pw.Font.ttf(await rootBundle.load(path));
    return SujetCopieFonts(
      body: await font('assets/fonts/inter/Inter_18pt-Regular.ttf'),
      bodyBold: await font('assets/fonts/inter/Inter_18pt-SemiBold.ttf'),
      title: await font('assets/fonts/lora/Lora-SemiBold.ttf'),
      italic: await font('assets/fonts/lora/Lora-Italic.ttf'),
    );
  }
}
