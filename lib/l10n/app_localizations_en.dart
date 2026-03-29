// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get schoolApp => 'ETEELO TECH';

  @override
  String get logout => 'Logout';

  @override
  String welcome(String name) {
    return 'Welcome$name!';
  }

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get receiveOtp => 'Receive an OTP code';

  @override
  String get enterEmailToReceiveOtp => 'Enter your email to receive a verification code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpValidation => 'OTP Validation';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String codeSentTo(String email) {
    return 'Code sent to $email';
  }

  @override
  String get otpCodeLabel => 'OTP Code';

  @override
  String get validateCode => 'Validate code';

  @override
  String get otpMustBeSixDigits => 'OTP code must contain 6 digits';

  @override
  String get newPassword => 'New password';

  @override
  String get chooseNewPassword => 'Choose a new password';

  @override
  String account(String email) {
    return 'Account: $email';
  }

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get validateAndLogin => 'Validate and Login';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get menuInscriptions => 'Registrations';

  @override
  String get menuFinances => 'Finances';

  @override
  String get menuClasses => 'Classes';

  @override
  String get menuDisciplines => 'Disciplines';

  @override
  String get subMenuDashboard => 'Dashboard';

  @override
  String get subMenuPreRegistrations => 'Pre-Registrations';

  @override
  String get subMenuReRegistrations => 'Re-Registrations';

  @override
  String get subMenuFirstRegistration => 'First Registration';

  @override
  String get subMenuBilling => 'Billing';

  @override
  String get subMenuOrganization => 'Organization';

  @override
  String get subMenuClassesList => 'Classes List';

  @override
  String get subMenuAttendance => 'Attendance';

  @override
  String get subMenuDisciplinesList => 'Disciplines List';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get pageUnderConstruction => 'This page is under development';
}
