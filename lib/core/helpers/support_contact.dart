import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre le client mail vers le support — l'action « Contacter
/// l'administrateur » d'un refus 403. Fonction top-level : aucun `context`
/// après l'`await`, donc aucune garde `mounted` à poser chez l'appelant.
Future<void> contactSupport() =>
    launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
