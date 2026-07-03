import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre le client mail vers le support (action « Contacter l'admin » du 403).
/// Fonction top-level (pas de `context` après l'`await` → pas de garde mounted).
Future<void> resultatsContactSupport() =>
    launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
