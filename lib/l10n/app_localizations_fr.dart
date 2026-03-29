// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get hello => 'Bonjour';

  @override
  String get login => 'Connexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get passwordTooShort => 'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre email';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un email valide';

  @override
  String get schoolApp => 'ETEELO TECH';

  @override
  String get logout => 'Déconnexion';

  @override
  String welcome(String name) {
    return 'Bienvenue$name !';
  }

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get receiveOtp => 'Recevoir un code OTP';

  @override
  String get enterEmailToReceiveOtp => 'Saisissez votre email pour recevoir un code de vérification.';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get otpValidation => 'Validation OTP';

  @override
  String get enterSixDigitCode => 'Entrez le code à 6 chiffres';

  @override
  String codeSentTo(String email) {
    return 'Code envoyé à $email';
  }

  @override
  String get otpCodeLabel => 'Code OTP';

  @override
  String get validateCode => 'Valider le code';

  @override
  String get otpMustBeSixDigits => 'Le code OTP doit contenir 6 chiffres';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get chooseNewPassword => 'Choisissez un nouveau mot de passe';

  @override
  String account(String email) {
    return 'Compte: $email';
  }

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get validateAndLogin => 'Valider et se connecter';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get menuInscriptions => 'Inscriptions';

  @override
  String get menuFinances => 'Finances';

  @override
  String get menuClasses => 'Classes';

  @override
  String get menuDisciplines => 'Disciplines';

  @override
  String get subMenuDashboard => 'Tableau de Bord';

  @override
  String get subMenuPreRegistrations => 'Pré-Inscriptions';

  @override
  String get subMenuReRegistrations => 'Re-Inscriptions';

  @override
  String get subMenuFirstRegistration => 'Première Inscription';

  @override
  String get subMenuBilling => 'Facturations';

  @override
  String get subMenuOrganization => 'Organisation';

  @override
  String get subMenuClassesList => 'Classes';

  @override
  String get subMenuAttendance => 'Présences';

  @override
  String get subMenuDisciplinesList => 'Disciplines';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get home => 'Accueil';

  @override
  String get pageUnderConstruction => 'Cette page est en cours de développement';
}
