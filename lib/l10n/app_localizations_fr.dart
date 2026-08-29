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
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre email';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un email valide';

  @override
  String get loginEyebrow => 'Espace direction';

  @override
  String get loginSubtitle => 'Accédez au tableau de bord de votre école.';

  @override
  String get loginEmailLabel => 'Adresse e-mail';

  @override
  String get loginSubmitting => 'Connexion…';

  @override
  String get loginSignature => 'eteyelo · l\'école en lingala';

  @override
  String get loginBrandTitle => 'L\'école congolaise reliée au numérique.';

  @override
  String get loginBrandTitleCondensed => 'L\'école reliée au numérique.';

  @override
  String get loginBrandTitleHighlight => 'numérique';

  @override
  String get loginBrandSubtitle =>
      'Inscriptions, finances, classes et présences — une seule application, sur tout écran.';

  @override
  String get loginEmailRequired => 'L\'adresse e-mail est requise.';

  @override
  String get loginEmailInvalid => 'Format d\'e-mail invalide.';

  @override
  String get loginPasswordRequired => 'Le mot de passe est requis.';

  @override
  String get loginErrorInvalidCredentials =>
      'E-mail ou mot de passe incorrect. Vérifiez vos identifiants et réessayez.';

  @override
  String get loginErrorNetwork => 'Pas de connexion. Vérifiez votre réseau.';

  @override
  String get loginErrorAccountDisabled =>
      'Compte désactivé. Contactez l\'administrateur de votre école.';

  @override
  String get loginErrorServer => 'Erreur serveur. Réessayez dans un instant.';

  @override
  String loginErrorRateLimited(int seconds) {
    return 'Trop de tentatives. Réessayez dans $seconds s';
  }

  @override
  String get loginContactAdmin => 'Contacter l\'administrateur';

  @override
  String get loginErrorOfflineFirstLogin =>
      'Pas de connexion, et ce compte ne s\'est jamais connecté sur cette tablette. Une première connexion en ligne est nécessaire.';

  @override
  String get loginErrorOfflineWindowExpired =>
      'Période de travail hors-ligne expirée. Reconnectez-vous en ligne dès que le réseau revient.';

  @override
  String get showPassword => 'Afficher';

  @override
  String get hidePassword => 'Masquer';

  @override
  String get schoolApp => 'ETEELO CONNECT';

  @override
  String get splashBrandPrimary => 'ETEELO';

  @override
  String get splashBrandSecondary => 'CONNECT';

  @override
  String get splashTagline => 'Simplifier la gestion de votre école';

  @override
  String get splashSemanticsLabel => 'ETEELO CONNECT — écran de démarrage';

  @override
  String get sessionOfflineBanner => 'Session hors-ligne — vérifiée localement';

  @override
  String get sessionWarningBanner =>
      'Session à rafraîchir — reconnectez-vous bientôt';

  @override
  String get sessionReadOnlyBanner =>
      'Lecture seule — reconnexion en ligne requise';

  @override
  String get splashErrorTitle => 'Connexion impossible';

  @override
  String get splashErrorMessage =>
      'Impossible de charger les données de l\'application. Vérifiez votre connexion, puis réessayez.';

  @override
  String get splashErrorRetry => 'Réessayer';

  @override
  String get accueilUnknownRightsTitle => 'Droits non connus';

  @override
  String get accueilUnknownRightsMessage =>
      'Vos droits ne sont pas encore connus sur cet appareil. Reconnectez-vous en ligne pour les récupérer.';

  @override
  String get accueilNoAccessTitle => 'Aucun module accessible';

  @override
  String get accueilNoAccessMessage =>
      'Votre compte ne donne accès à aucun module. Contactez l\'administrateur de votre école pour qu\'il ajuste vos droits.';

  @override
  String get accueilNoAccessOfflineMessage =>
      'Votre session a été ouverte hors ligne et aucun droit n\'est connu pour ce compte. Reconnectez-vous en ligne dès que le réseau est disponible.';

  @override
  String get splashForbiddenTitle => 'Accès non autorisé';

  @override
  String get splashForbiddenMessage =>
      'Votre compte ne dispose pas des droits nécessaires pour ouvrir l\'application. Contactez l\'administrateur de votre école.';

  @override
  String get splashNotProvisionedTitle => 'École pas encore paramétrée';

  @override
  String get splashNotProvisionedMessage =>
      'Cette école n\'a pas encore d\'année scolaire ouverte. La configuration déclare l\'année, les classes et les frais, puis met l\'établissement en service.';

  @override
  String get splashNotProvisionedAction => 'Configurer l\'école';

  @override
  String get splashNotProvisionedWaitMessage =>
      'Cette école n\'a pas encore d\'année scolaire ouverte. Seule la direction peut la configurer — rapprochez-vous d\'elle avant de réessayer.';

  @override
  String get configurationTitle => 'Configuration';

  @override
  String get configurationSubtitle => 'Mise en service de l\'école';

  @override
  String configurationStepCounter(int current, int total) {
    return 'Étape $current / $total';
  }

  @override
  String get configurationExitTooltip => 'Quitter la configuration';

  @override
  String get configurationStepSchool => 'École';

  @override
  String get configurationStepAcademicYear => 'Année';

  @override
  String get configurationStepStructure => 'Structure';

  @override
  String get configurationStepFees => 'Frais';

  @override
  String get configurationStepActivation => 'Activation';

  @override
  String configurationStepSemantics(int current, int total, String title) {
    return 'Étape $current sur $total, $title';
  }

  @override
  String get configurationBack => 'Retour';

  @override
  String get configurationSave => 'Enregistrer';

  @override
  String get configurationContinue => 'Continuer';

  @override
  String get configurationSaving => 'Enregistrement…';

  @override
  String get configurationSaved => 'Enregistré';

  @override
  String get configurationDraftSaved => 'Brouillon enregistré';

  @override
  String get configurationSaveBarDefaultHint =>
      'Complétez les champs obligatoires pour continuer';

  @override
  String get configurationSchoolSectionTitle => 'Identité de l\'école';

  @override
  String get configurationSchoolSectionSubtitle =>
      'Ces informations apparaissent sur les attestations, reçus et bulletins.';

  @override
  String get configurationSchoolName => 'Dénomination de l\'école';

  @override
  String get configurationSchoolCountry => 'Pays';

  @override
  String get configurationSchoolCity => 'Ville';

  @override
  String get configurationSchoolDistrict => 'District';

  @override
  String get configurationSchoolMunicipality => 'Commune';

  @override
  String get configurationSchoolMunicipalityPlaceholder => 'District d\'abord';

  @override
  String get configurationSchoolAddress => 'Adresse';

  @override
  String get configurationSchoolPhone => 'Téléphone de l\'école';

  @override
  String get configurationSchoolEmail => 'E-mail de l\'école';

  @override
  String configurationSchoolMissingHint(String fields) {
    return 'À compléter : $fields';
  }

  @override
  String get configurationSchoolReadOnlyNote =>
      'Pays et ville sont fixés : l\'application est déployée à Kinshasa.';

  @override
  String get configurationYearSectionTitle => 'Année académique';

  @override
  String get configurationYearSectionSubtitle =>
      'Une première année est proposée d\'après la date du jour — ajustez les dates si besoin.';

  @override
  String get configurationYearProposed => 'Proposée automatiquement';

  @override
  String get configurationYearEdited => 'Modifiée';

  @override
  String get configurationYearRestore => 'Rétablir la proposition';

  @override
  String get configurationYearStart => 'Début des cours';

  @override
  String get configurationYearEnd => 'Fin de l\'année';

  @override
  String get configurationYearDuration => 'Durée';

  @override
  String configurationYearDurationValue(int months) {
    return '≈ $months mois';
  }

  @override
  String get configurationYearRangeError => 'La fin doit suivre le début';

  @override
  String get configurationYearPeriodsNote =>
      'Le découpage en périodes (trimestres, semestres) se règle plus tard, dans Résultats.';

  @override
  String get configurationStructureTitle => 'Cycles, niveaux et classes';

  @override
  String configurationTotalCycles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cycles',
      one: 'cycle',
    );
    return '$_temp0';
  }

  @override
  String configurationTotalLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'niveaux',
      one: 'niveau',
    );
    return '$_temp0';
  }

  @override
  String configurationTotalClassrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'classes',
      one: 'classe',
    );
    return '$_temp0';
  }

  @override
  String configurationTotalCourses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cours',
      one: 'cours',
    );
    return '$_temp0';
  }

  @override
  String get configurationCycleClassroomsPerLevel => 'Classes par niveau';

  @override
  String get configurationCycleNotOffered => 'Non proposé';

  @override
  String configurationCycleSummary(int open, int total, int classrooms) {
    String _temp0 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms classe',
    );
    return '$open / $total · $_temp0';
  }

  @override
  String get configurationLevelNotOffered => 'Niveau non proposé cette année';

  @override
  String get configurationLevelNoGrid =>
      'Aucun barème officiel — ces classes n\'auront aucun cours.';

  @override
  String configurationSectionsServed(String level) {
    return 'Barèmes servis sur $level';
  }

  @override
  String configurationSectionCourses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cours',
      one: '$count cours',
    );
    return '$_temp0';
  }

  @override
  String configurationStructureHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes seront créées pour l\'année',
      one: '$count classe sera créée pour l\'année',
    );
    return '$_temp0';
  }

  @override
  String get configurationStructureEmptyHint => 'Cochez au moins un niveau';

  @override
  String get configurationStructureEmptyTitle => 'Aucun niveau retenu';

  @override
  String get configurationStructureEmptyMessage =>
      'Une école a besoin d\'au moins une classe pour ouvrir les inscriptions. Rétablissez la proposition par défaut ou cochez les niveaux que vous ouvrez.';

  @override
  String get configurationStructureRestore => 'Rétablir la proposition';

  @override
  String get configurationFeesTitle => 'Frais scolaires';

  @override
  String get configurationFeeNew => 'Nouveau frais';

  @override
  String get configurationFeeFormTitle => 'Nouveau frais';

  @override
  String get configurationFeeFormEditTitle => 'Modifier le frais';

  @override
  String get configurationFeeType => 'Type de frais';

  @override
  String configurationFeeTypeOthers(int count) {
    return 'Autres types ($count)';
  }

  @override
  String get configurationFeeLabel => 'Libellé affiché aux parents';

  @override
  String get configurationFeeAmount => 'Montant';

  @override
  String get configurationFeeCurrency => 'Devise';

  @override
  String get configurationFeeDueAt => 'Échéance';

  @override
  String get configurationFeeScope => 'Assiette';

  @override
  String get configurationFeeScopeAll => 'Tous les niveaux ouverts';

  @override
  String get configurationFeeScopeSome => 'Certains niveaux';

  @override
  String configurationFeeScopeAllHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niveaux ouverts',
      one: '$count niveau ouvert',
    );
    return 'S\'appliquera aux $_temp0';
  }

  @override
  String configurationFeeScopeCount(int selected, int total) {
    return '$selected / $total sélectionnés';
  }

  @override
  String get configurationFeeScopeWholeCycle => 'Tout le cycle';

  @override
  String get configurationFeeAdd => 'Ajouter le frais';

  @override
  String get configurationFeeUpdate => 'Mettre à jour';

  @override
  String get configurationFeeCancel => 'Annuler';

  @override
  String configurationFeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frais définis',
      one: '$count frais défini',
      zero: 'Aucun frais défini',
    );
    return '$_temp0';
  }

  @override
  String configurationFeeCatalogTotal(String total) {
    return 'Total catalogue : $total';
  }

  @override
  String get configurationFeePerStudent => 'par élève';

  @override
  String configurationFeeLevelsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niveaux',
      one: '$count niveau',
    );
    return '$_temp0';
  }

  @override
  String configurationFeeDueLabel(String date) {
    return 'échéance $date';
  }

  @override
  String configurationFeeDeleted(String label) {
    return 'Frais « $label » supprimé';
  }

  @override
  String configurationFeeSaved(String label) {
    return 'Frais « $label » enregistré';
  }

  @override
  String get configurationFeesEmptyTitle => 'Aucun frais pour l\'instant';

  @override
  String get configurationFeesEmptyMessage =>
      'Ajoutez au moins un frais — inscription, minerval, cantine — pour que la facturation puisse générer les notes de perception.';

  @override
  String get configurationFeesEmptyAction => 'Créer le premier frais';

  @override
  String get configurationFeesEmptyHint =>
      'Ajoutez au moins un frais pour continuer';

  @override
  String get configurationFeesDraftHint =>
      'Terminez le frais en cours d\'édition';

  @override
  String configurationFeesValidHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frais seront rattachés aux niveaux ouverts',
      one: '$count frais sera rattaché aux niveaux ouverts',
    );
    return '$_temp0';
  }

  @override
  String get configurationSummaryTitle => 'Récapitulatif';

  @override
  String get configurationSummaryEdit => 'Modifier';

  @override
  String get configurationSummarySchool => 'École';

  @override
  String get configurationSummaryYear => 'Année académique';

  @override
  String configurationSummaryStructure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '$count classe',
    );
    return 'Structure · $_temp0';
  }

  @override
  String get configurationSummaryFees => 'Frais scolaires';

  @override
  String get configurationSummaryMissing => 'à renseigner';

  @override
  String configurationSummaryCycleLine(int levels, int classrooms) {
    String _temp0 = intl.Intl.pluralLogic(
      levels,
      locale: localeName,
      other: '$levels niveaux',
      one: '$levels niveau',
    );
    String _temp1 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms classe',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get configurationSummaryNoGrid => 'aucun barème';

  @override
  String get configurationCheckSchool => 'Identité de l\'école complète';

  @override
  String get configurationCheckYear => 'Année académique datée';

  @override
  String configurationCheckClassrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes prêtes à ouvrir',
      one: '$count classe prête à ouvrir',
      zero: 'Aucune classe à ouvrir',
    );
    return '$_temp0';
  }

  @override
  String configurationCheckFees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frais rattachés aux niveaux',
      one: '$count frais rattaché aux niveaux',
      zero: 'Aucun frais rattaché aux niveaux',
    );
    return '$_temp0';
  }

  @override
  String get configurationActivate => 'Activer l\'école';

  @override
  String get configurationActivating => 'Activation…';

  @override
  String get configurationActivateBlocked =>
      'Complétez les points en ambre pour activer.';

  @override
  String get configurationActivateFailed =>
      'L\'activation a échoué — réessayez.';

  @override
  String configurationActivatedTitle(String school) {
    return '$school est en service';
  }

  @override
  String configurationActivatedMessage(String year, int classrooms, int fees) {
    String _temp0 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms classe',
    );
    String _temp1 = intl.Intl.pluralLogic(
      fees,
      locale: localeName,
      other: '$fees frais',
      one: '$fees frais',
    );
    return 'L\'année $year est ouverte avec $_temp0 et $_temp1. Vous pouvez inscrire vos premiers élèves.';
  }

  @override
  String get configurationGoHome => 'Aller à l\'accueil';

  @override
  String get configurationReviewSetup => 'Revoir la configuration';

  @override
  String get configurationWarningsTitle => 'À savoir avant d\'activer';

  @override
  String get menuConfiguration => 'Configuration';

  @override
  String get subMenuConfigurationSchool => 'Paramètres de l\'école';

  @override
  String get configurationSettingsTitle => 'Configuration de l\'école';

  @override
  String configurationSettingsInService(String school) {
    return '$school · en service';
  }

  @override
  String configurationSettingsSummary(String year, int classrooms, int levels) {
    String _temp0 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms classe',
    );
    String _temp1 = intl.Intl.pluralLogic(
      levels,
      locale: localeName,
      other: '$levels niveaux',
      one: '$levels niveau',
    );
    return 'Année $year · $_temp0 · $_temp1';
  }

  @override
  String get configurationSettingsNextYear => 'Préparer l\'année suivante';

  @override
  String get configurationSettingsNextYearTooltip =>
      'Indisponible pour l\'instant : l\'assistant ne peut pas être rejoué, le serveur refuserait une année déjà ouverte. Un geste dédié reste à livrer.';

  @override
  String get configurationSettingsTabIdentity => 'Identité de l\'école';

  @override
  String get configurationSettingsTabStructure => 'Cycles, niveaux et classes';

  @override
  String get configurationSettingsTabFees => 'Frais scolaires';

  @override
  String get configurationSettingsReadOnly => 'lecture';

  @override
  String get configurationSettingsStructureReadOnlyNote =>
      'La structure ne se modifie plus après la mise en service. Le serveur ne sait pas encore refuser proprement la suppression d\'un niveau peuplé : la câbler ici risquerait de casser des inscriptions en cours.';

  @override
  String get configurationSettingsSaved => 'Modifications enregistrées';

  @override
  String get configurationSettingsSave => 'Enregistrer';

  @override
  String get configurationSettingsNoYear => 'Aucune année ouverte';

  @override
  String configurationSettingsTariffsForLevel(String level) {
    return 'Tarifs de $level';
  }

  @override
  String get configurationSettingsTariffOne =>
      'Ici, un tarif porte un seul niveau : chaque ligne se modifie séparément.';

  @override
  String get configurationTariffAdd => 'Ajouter un tarif';

  @override
  String get configurationTariffEdit => 'Modifier le tarif';

  @override
  String get configurationTariffNew => 'Nouveau tarif';

  @override
  String get configurationTariffDelete => 'Supprimer le tarif';

  @override
  String configurationTariffDeleteConfirm(String label) {
    return 'Supprimer « $label » ? Les créances déjà générées ne sont pas touchées.';
  }

  @override
  String get configurationTariffSaved => 'Tarif enregistré';

  @override
  String get configurationTariffDeleted => 'Tarif supprimé';

  @override
  String get configurationTariffNone => 'Aucun tarif sur ce niveau';

  @override
  String get configurationFeeTypesUnavailableTitle =>
      'Types de frais indisponibles';

  @override
  String get configurationFeeTypesUnavailableMessage =>
      'Le référentiel des types de frais n\'a pas été chargé. Rechargez-le pour saisir les frais de l\'école.';

  @override
  String get configurationLoadingA11yLabel =>
      'Chargement des données de l\'étape';

  @override
  String get configurationErrorNetworkTitle => 'Connexion perdue';

  @override
  String get configurationErrorNetworkMessage =>
      'La configuration n\'a pas été envoyée. Vérifiez votre connexion, puis réessayez.';

  @override
  String get configurationErrorSessionTitle => 'Votre session a expiré';

  @override
  String get configurationErrorSessionMessage =>
      'Reconnectez-vous pour reprendre là où vous en étiez. Votre saisie est conservée.';

  @override
  String get configurationErrorForbiddenTitle => 'Accès refusé';

  @override
  String get configurationErrorForbiddenMessage =>
      'Seul le promoteur peut configurer l\'école. Contactez l\'administrateur de votre établissement.';

  @override
  String get configurationErrorServerTitle =>
      'Le serveur n\'a pas pu enregistrer';

  @override
  String get configurationErrorServerMessage =>
      'Une panne est survenue. Réessayez, et citez le code ci-dessous au support si elle persiste.';

  @override
  String get configurationErrorRateTitle => 'Trop de demandes';

  @override
  String get configurationErrorRateMessage =>
      'Le serveur demande une pause. Patientez quelques instants avant de reprendre.';

  @override
  String get configurationErrorYearExistsTitle =>
      'Cette année scolaire existe déjà';

  @override
  String get configurationErrorYearExistsMessage =>
      'Le paramétrage est un geste d\'amorçage : il n\'ajoute pas une année à une école qui en a déjà une. Reprenez à l\'étape de l\'année pour en déclarer une autre.';

  @override
  String get configurationErrorYearExistsAction => 'Revenir à l\'année';

  @override
  String get configurationErrorRetry => 'Réessayer';

  @override
  String get configurationErrorSignIn => 'Se reconnecter';

  @override
  String get configurationErrorContact => 'Contacter l\'administrateur';

  @override
  String get configurationErrorIncident => 'Code incident';

  @override
  String get configurationErrorReloadCatalog => 'Recharger le référentiel';

  @override
  String splashVersion(String version, String build) {
    return 'v$version (build $build)';
  }

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
  String get enterEmailToReceiveOtp =>
      'Saisissez votre email pour recevoir un code de vérification.';

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
  String get resetEyebrow => 'Réinitialisation';

  @override
  String get resetBrandTitle => 'Récupération d\'accès en toute sécurité.';

  @override
  String get resetBrandTitleCondensed => 'Récupération d\'accès.';

  @override
  String get resetBrandTitleHighlight => 'd\'accès';

  @override
  String get resetBrandSubtitle =>
      'Réinitialisez votre mot de passe en toute sécurité.';

  @override
  String resetStepIndicator(int step, int total, String label) {
    return 'Étape $step sur $total · $label';
  }

  @override
  String get resetStepLabelEmail => 'E-mail';

  @override
  String get resetStepLabelCode => 'Code';

  @override
  String get resetStepLabelPassword => 'Nouveau mot de passe';

  @override
  String get resetBackToLogin => 'Retour';

  @override
  String get menuInscriptions => 'Inscriptions';

  @override
  String get menuFinances => 'Finances';

  @override
  String get menuClasses => 'Classes';

  @override
  String get menuDisciplines => 'Disciplines';

  @override
  String get subMenuDashboard => 'Tableau de bord';

  @override
  String get subMenuPreRegistrations => 'Pré-inscriptions';

  @override
  String get subMenuReRegistrations => 'Réinscriptions';

  @override
  String get subMenuFirstRegistration => 'Première inscription';

  @override
  String get subMenuBilling => 'Facturations';

  @override
  String get subMenuFeeControl => 'Contrôle des frais';

  @override
  String get subMenuOrganization => 'Composition\ndes classes';

  @override
  String get classesOrganisationHeroTitle => 'Composition des classes';

  @override
  String get classesOrganisationHeroSubtitle =>
      'Repartissez les élèves d\'un niveau en sous-classes (ex. 1ere année A, 1ere année B, 1ere année C) et visualisez la liste des élèves par sous-classe.';

  @override
  String get classesOrganisationSearchTitle =>
      'Sélection du niveau à organiser';

  @override
  String classesOrganisationHeaderEyebrow(String schoolYear) {
    return 'Composition des classes · Année $schoolYear';
  }

  @override
  String get classesOrganisationLevelPlaceholder =>
      'Choisissez d\'abord un cycle';

  @override
  String get classesOrganisationSearchHint =>
      'Sélectionnez le cycle et le niveau à organiser, puis lancez la recherche pour afficher la répartition actuelle ou préparer la distribution en sous-classes.';

  @override
  String get classesOrganisationClassroomFieldLabel => 'Sous-classe';

  @override
  String get classesOrganisationDistributionLabel => 'Critère de répartition';

  @override
  String get classesOrganisationDistributionByGender => 'Répartition par genre';

  @override
  String get classesOrganisationDistributionByPercentage =>
      'Répartition par moyenne';

  @override
  String get classesOrganisationDistributeByGenderAction =>
      'Lancer la répartition par genre';

  @override
  String get classesOrganisationDistributeOfflineHint =>
      'Vous semblez hors-ligne. Une connexion est nécessaire pour lancer la répartition.';

  @override
  String get classesOrganisationDistributeLoadErrorHint =>
      'Impossible de calculer l\'effectif à répartir pour le moment. Réessayez plus tard.';

  @override
  String get classesDistributionResultEyebrow => 'Répartition par genre';

  @override
  String get classesDistributionProcessingTitle => 'Répartition en cours…';

  @override
  String get classesDistributionSuccessTitle => 'Répartition réussie';

  @override
  String get classesDistributionSuccessSubtitle =>
      'Les élèves ont été répartis de façon équilibrée par genre.';

  @override
  String get classesDistributionRecapTitle => 'Effectif par classe';

  @override
  String classesDistributionClassHeadcount(int count) {
    return '$count élèves';
  }

  @override
  String get classesDistributionErrorTitle => 'Échec de la répartition';

  @override
  String get classesDistributionErrorMessage =>
      'Les classes sont restées intactes. Vous pouvez réessayer.';

  @override
  String get classesDistributionRetry => 'Réessayer';

  @override
  String get classesDistributionClose => 'Fermer';

  @override
  String get classesDistributionKpiHeadcount => 'Effectif';

  @override
  String get classesDistributionKpiClasses => 'Classes';

  @override
  String get classesDistributionKpiBoys => 'Garçons';

  @override
  String get classesDistributionKpiGirls => 'Filles';

  @override
  String get classesDistributionViewGrid => 'Grille';

  @override
  String get classesDistributionViewList => 'Liste';

  @override
  String classesDistributionClassLabel(String code) {
    return 'Classe $code';
  }

  @override
  String classesDistributionClassCapacity(int count, int capacity) {
    return '$count élèves · capacité $capacity';
  }

  @override
  String get classesDistributionCapacityFull => 'complet';

  @override
  String get classesOrganisationDistributionSuccess =>
      'Répartition terminée avec succès.';

  @override
  String get classesOrganisationSplitInfo =>
      'Mode sous-classes actif : affichage par sous-classe avec effectifs et statistiques.';

  @override
  String get classesOrganisationNonSplitInfo =>
      'Mode classe unique actif : liste des élèves du niveau sélectionné.';

  @override
  String get classesOrganisationLoadingTitle => 'Chargement des classes…';

  @override
  String get classesOrganisationEmptyTitle => 'Aucun élève à répartir';

  @override
  String get classesOrganisationEmptyInvite =>
      'Inscrivez des élèves dans ce niveau pour lancer la répartition.';

  @override
  String get classesOrganisationOverviewErrorTitle => 'Chargement impossible';

  @override
  String get classesOrganisationTransferDialogTitle => 'Transférer l\'élève';

  @override
  String get classesReassignCurrentClassState => 'Classe actuelle';

  @override
  String get classesReassignUnassignedState => 'Non réparti';

  @override
  String get classesReassignCurrentBadge => 'Actuelle';

  @override
  String get classesReassignFullBadge => 'Complet';

  @override
  String classesReassignOptionStats(int eff, int cap, int boys, int girls) {
    return '$eff/$cap · G $boys · F $girls';
  }

  @override
  String get classesOrganisationTransferAction => 'Transférer';

  @override
  String get classesOrganisationTransferInProgress => 'Transfert en cours...';

  @override
  String get classesOrganisationTransferQueued =>
      'Transfert enregistré — en attente de synchronisation.';

  @override
  String get classesOrganisationTransferPendingBadge => 'En attente';

  @override
  String get classesOrganisationTransferNoTarget =>
      'Aucune sous-classe de destination disponible.';

  @override
  String get classesOrganisationSelectCycleAndLevelTitle =>
      'Sélectionnez un cycle et un niveau';

  @override
  String get classesOrganisationSelectCycleAndLevelSubtitle =>
      'Commencez par choisir un cycle, puis un niveau pour afficher la composition des classes.';

  @override
  String get classesOrganisationSelectLevelTitle => 'Sélectionnez un niveau';

  @override
  String classesOrganisationSelectLevelSubtitle(String cycleName) {
    return 'Choisissez maintenant un niveau dans le cycle $cycleName.';
  }

  @override
  String get classesOrganisationPendingTitle => 'Niveau pas encore réparti';

  @override
  String classesOrganisationPendingMessage(int count, String levelName) {
    return 'Les $count élèves de $levelName ne sont rattachés à aucune classe. La répartition automatique équilibre les classes par genre.';
  }

  @override
  String classesOrganisationPendingStudentsToDistribute(int count) {
    return '$count élèves à répartir';
  }

  @override
  String classesOrganisationGenderBoysPill(int count) {
    return 'G · $count';
  }

  @override
  String classesOrganisationGenderGirlsPill(int count) {
    return 'F · $count';
  }

  @override
  String get classesOrganisationUnassignedTitle => 'Élèves non répartis';

  @override
  String get classesOrganisationUnassignedSubtitle =>
      'Nouveaux arrivants, transferts annulés…';

  @override
  String get classesOrganisationUnassignedBadge => 'À affecter';

  @override
  String get classesOrganisationNoMembers => 'Aucun élève dans cette classe.';

  @override
  String get classesOrganisationAssignAction => 'Affecter';

  @override
  String get classesOrganisationAssignDialogTitle => 'Affecter l\'élève';

  @override
  String get classesOrganisationAssignSuccess => 'Élève affecté à la classe.';

  @override
  String get classesOrganisationAssignRejected =>
      'Affectation refusée : cet élève est déjà dans une classe, ou son inscription n\'est pas sur ce niveau. Actualisez la liste.';

  @override
  String get classesOrganisationAssignNotFound =>
      'Classe ou inscription introuvable. Actualisez la liste.';

  @override
  String classesOrganisationLoadingClassroomsCount(int count) {
    return 'Chargement des membres de $count sous-classes...';
  }

  @override
  String get classesOrganisationStudentDetailSoon =>
      'Le détail élève sera disponible au prochain lot.';

  @override
  String get classesOrganisationErrorNetwork =>
      'Vérifiez votre connexion internet.';

  @override
  String get classesOrganisationErrorNotFound =>
      'Aucune donnée trouvée pour ces critères.';

  @override
  String get classesOrganisationErrorValidation =>
      'Certaines informations saisies sont invalides.';

  @override
  String get classesOrganisationErrorUnauthorized => 'Accès non autorisé.';

  @override
  String get classesOrganisationErrorInvalidCredentials =>
      'Identifiants invalides.';

  @override
  String get classesOrganisationErrorServer =>
      'Erreur serveur, réessayez plus tard.';

  @override
  String get classesOrganisationErrorStorage => 'Erreur de stockage local.';

  @override
  String get classesOrganisationErrorAuth =>
      'Session non valide, reconnectez-vous.';

  @override
  String get classesOrganisationErrorUnknown => 'Une erreur est survenue.';

  @override
  String get classesListSearchTitle => 'Formulaire de recherche';

  @override
  String get classesListSearchHint => '';

  @override
  String get classesListClassroomOptionalLabel => 'Classe (optionnel)';

  @override
  String get classesListClassroomPlaceholder => 'Choisissez d\'abord un niveau';

  @override
  String get classesListClassroomNonePlaceholder =>
      'Aucune classe pour ce niveau';

  @override
  String get classesListSearchLevelPlaceholder => 'Choisissez un cycle';

  @override
  String get classesListLevelColumnLabel => 'Niveau';

  @override
  String get classesListLevelUnknown => '—';

  @override
  String get classesListInitialEmptyTitle => 'Aucune recherche en cours';

  @override
  String get classesListInitialEmptyMessage =>
      'Choisissez un niveau, ou renseignez l\'identité complète d\'un élève, pour afficher des résultats.';

  @override
  String get classesListNoMatchTitle =>
      'Aucun élève ne correspond aux critères';

  @override
  String get classesListNoMatchMessage =>
      'Essayez d\'élargir vos filtres ou de modifier votre recherche.';

  @override
  String classesListResultsSummary(int count, String criteria) {
    return '$count élèves trouvés — $criteria';
  }

  @override
  String classesListResultsSummaryWithoutCriteria(int count) {
    return '$count élèves trouvés';
  }

  @override
  String get classesListClassroomChipLabel => 'Classe';

  @override
  String get classesListLoadingClassroomMembers =>
      'Chargement des membres de la classe...';

  @override
  String get classesListClassroomEmptyMessage =>
      'Aucun élève n\'est actuellement affecté à cette classe.';

  @override
  String get classesListClassroomFilteredEmptyMessage =>
      'Aucun élève de cette classe ne correspond aux filtres saisis.';

  @override
  String get classesListStudentDetailSoon =>
      'Le détail élève sera disponible dans une prochaine version.';

  @override
  String get classesListExportSuccess => 'Export copié dans le presse-papiers.';

  @override
  String get classesListExportFailed =>
      'Impossible de préparer l\'export pour le moment.';

  @override
  String get classesListExportNothingToExport =>
      'Aucune donnée à exporter pour cette recherche.';

  @override
  String get classesListExportPdf => 'Exporter en PDF';

  @override
  String get subMenuClassesList => 'Listes de classe';

  @override
  String get subMenuAttendance => 'Présences';

  @override
  String get subMenuDisciplinesList => 'Disciplines';

  @override
  String get menuCourses => 'Cours';

  @override
  String get subMenuMyCourses => 'Mes cours';

  @override
  String get subMenuTimetable => 'Emploi du temps';

  @override
  String myCoursesCount(int classCount, int courseCount) {
    String _temp0 = intl.Intl.pluralLogic(
      classCount,
      locale: localeName,
      other: '$classCount classes',
      one: '1 classe',
      zero: '0 classe',
    );
    String _temp1 = intl.Intl.pluralLogic(
      courseCount,
      locale: localeName,
      other: '$courseCount cours',
      one: '1 cours',
      zero: '0 cours',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String myCoursesUnsyncedClassroomNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cours masqués — classe non synchronisée',
      one: '1 cours masqué — classe non synchronisée',
    );
    return '$_temp0';
  }

  @override
  String get myCoursesUnsyncedClassroomName => 'Classe non synchronisée';

  @override
  String myCoursesDegradedClassroomNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count cours affichés sans leur classe — la synchronisation des classes n\'a pas encore abouti',
      one:
          '1 cours affiché sans sa classe — la synchronisation des classes n\'a pas encore abouti',
    );
    return '$_temp0';
  }

  @override
  String get myCoursesExpandAll => 'Tout déplier';

  @override
  String get myCoursesCollapseAll => 'Tout replier';

  @override
  String myCoursesClassCourseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cours',
      one: '1 cours',
      zero: '0 cours',
    );
    return '$_temp0';
  }

  @override
  String myCoursesStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count élèves',
      one: '1 élève',
      zero: 'Aucun élève',
    );
    return '$_temp0';
  }

  @override
  String get myCoursesLoadingA11yLabel => 'Chargement de vos cours';

  @override
  String get myCoursesEmptyTitle => 'Aucun cours affecté';

  @override
  String get myCoursesEmptyDescription =>
      'Aucun cours ne vous est rattaché pour le moment. Les cours que vous enseignez apparaîtront ici, regroupés par classe.';

  @override
  String get myCoursesErrorNetworkTitle => 'Pas de connexion';

  @override
  String get myCoursesErrorNetworkMessage =>
      'Vous semblez hors-ligne. Vérifiez votre connexion internet, puis réessayez.';

  @override
  String get myCoursesErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get myCoursesErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour consulter vos cours.';

  @override
  String get myCoursesErrorForbiddenTitle => 'Accès refusé';

  @override
  String get myCoursesErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour consulter ces cours.';

  @override
  String get myCoursesErrorServerTitle => 'Erreur du serveur';

  @override
  String get myCoursesErrorServerMessage =>
      'Une erreur est survenue de notre côté. Réessayez dans un instant.';

  @override
  String get myCoursesErrorUnknownTitle => 'Chargement impossible';

  @override
  String get myCoursesErrorUnknownMessage =>
      'Une erreur inattendue est survenue lors du chargement de vos cours.';

  @override
  String get myCoursesErrorRetry => 'Réessayer';

  @override
  String get myCoursesErrorReconnect => 'Se reconnecter';

  @override
  String get myCoursesErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String myCoursesErrorIncidentCode(String code) {
    return 'Code incident : $code';
  }

  @override
  String get courseDetailBackToCourses => 'Mes cours';

  @override
  String courseDetailEvaluationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count évaluations',
      one: '1 évaluation',
      zero: 'Aucune évaluation',
    );
    return '$_temp0';
  }

  @override
  String courseDetailToGrade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à saisir',
      one: '1 à saisir',
      zero: '0 à saisir',
    );
    return '$_temp0';
  }

  @override
  String get courseDetailNextEvalEyebrow => 'Prochaine évaluation';

  @override
  String courseDetailEvalMetaShort(String date, String max) {
    return '$date · /$max pts';
  }

  @override
  String courseDetailEvalMeta(String date, String max, int poids) {
    return '$date · /$max pts · poids $poids';
  }

  @override
  String courseDetailSemesterLabel(int ordre) {
    return 'Semestre $ordre';
  }

  @override
  String courseDetailTrimesterLabel(int ordre) {
    return 'Trimestre $ordre';
  }

  @override
  String courseDetailPeriodLabel(int ordre) {
    return 'Période $ordre';
  }

  @override
  String get courseDetailExamLabel => 'Examen';

  @override
  String get courseDetailStatutClosed => 'Clôturée';

  @override
  String get courseDetailStatutCurrent => 'En cours';

  @override
  String get courseDetailStatutUpcoming => 'À venir';

  @override
  String courseDetailBucketNotes(int saisies, int total, int evals) {
    String _temp0 = intl.Intl.pluralLogic(
      evals,
      locale: localeName,
      other: '$evals éval.',
      one: '1 éval.',
      zero: '0 éval.',
    );
    return '$saisies/$total notes · $_temp0';
  }

  @override
  String get courseDetailBucketNoEval => 'Aucune évaluation';

  @override
  String get courseDetailExamToPlan => 'À planifier';

  @override
  String courseDetailNoteGlobaleTitle(String label) {
    return 'Note globale — $label';
  }

  @override
  String get courseDetailProvisional => 'provisoire';

  @override
  String get courseDetailClassAverageLabel => 'Moyenne de classe';

  @override
  String courseDetailAbove50(int count, int total) {
    return '$count/$total élèves ≥ 50 %';
  }

  @override
  String get courseDetailNoAverage => 'Pas encore de moyenne';

  @override
  String get courseDetailByStudent => 'Par élève';

  @override
  String get courseDetailBadgeGraded => 'Notée';

  @override
  String courseDetailBadgeInProgress(int saisies, int total) {
    return 'En cours · $saisies/$total';
  }

  @override
  String get courseDetailBadgeUpcoming => 'À venir';

  @override
  String courseDetailEvalExpected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count élèves attendus',
      one: '1 élève attendu',
      zero: '0 élève attendu',
    );
    return '$_temp0';
  }

  @override
  String courseDetailReleveTitle(String label) {
    return 'Notes globales — $label';
  }

  @override
  String get courseDetailReleveKpiAverage => 'Moyenne';

  @override
  String get courseDetailReleveKpiAbove50 => '≥ 50 %';

  @override
  String get courseDetailReleveKpiEvals => 'Évals';

  @override
  String get courseDetailSortRanking => 'Classement';

  @override
  String get courseDetailSortAlpha => 'Alphabétique';

  @override
  String get courseDetailReleveMethod =>
      'Note globale = points obtenus ÷ maximum, pondérés par le poids.';

  @override
  String get courseDetailReleveEmpty => 'Aucune note saisie';

  @override
  String get courseDetailLoadingA11yLabel => 'Chargement du cours';

  @override
  String get courseDetailEmptyTitle => 'Aucune évaluation';

  @override
  String get courseDetailEmptyDescription =>
      'Ce cours n\'a pas encore d\'évaluation.';

  @override
  String get courseDetailBucketEmptyUpcoming =>
      'Sélection à venir — aucune évaluation planifiée pour l\'instant.';

  @override
  String get courseDetailBucketEmptyNone =>
      'Aucune évaluation rattachée à cette sélection.';

  @override
  String get courseDetailErrorNetworkMessage =>
      'Vous semblez hors-ligne. Vérifiez votre connexion, puis réessayez.';

  @override
  String get courseDetailErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour consulter ce cours.';

  @override
  String get courseDetailErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour consulter ce cours.';

  @override
  String get courseDetailErrorServerMessage =>
      'Une erreur est survenue de notre côté. Réessayez dans un instant.';

  @override
  String get courseDetailErrorUnknownMessage =>
      'Une erreur inattendue est survenue lors du chargement du cours.';

  @override
  String get courseDetailErrorNotFoundTitle => 'Cours introuvable';

  @override
  String get courseDetailErrorNotFoundMessage =>
      'Ce cours n\'existe plus ou n\'est pas accessible.';

  @override
  String get evalTypeInterro => 'Interrogation';

  @override
  String get evalTypeDevoir => 'Devoir';

  @override
  String get evalTypeExamen => 'Examen';

  @override
  String get evalCreateTitle => 'Nouvelle évaluation';

  @override
  String get evalCreateFieldSemestre => 'Semestre';

  @override
  String get evalCreateFieldTrimestre => 'Trimestre';

  @override
  String get evalCreateFieldSousPeriode => 'Période';

  @override
  String get evalCreateExamPlaceholder => 'Examen semestriel';

  @override
  String get evalCreateFieldDate => 'Date';

  @override
  String get evalCreateFieldDateHint => 'jj/mm/aaaa';

  @override
  String get evalCreateFieldMax => 'Maximum';

  @override
  String get evalCreateFieldPoids => 'Poids';

  @override
  String get evalCreateFieldChapitres => 'Chapitres concernés';

  @override
  String get evalCreateChapitresEmpty =>
      'Aucun chapitre disponible pour ce cours';

  @override
  String get evalCreateCancel => 'Annuler';

  @override
  String get evalCreateSubmit => 'Créer l\'évaluation';

  @override
  String evalCreateHint(int count, String classroom) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count élèves de $classroom seront ajoutés',
      one: 'L\'élève de $classroom sera ajouté',
      zero: 'Aucun élève de $classroom ne sera ajouté',
    );
    return '$_temp0 avec le statut « En attente ».';
  }

  @override
  String get evalCreateSuccessToast => 'Évaluation créée';

  @override
  String get evalCreateErrorToast =>
      'La création de l\'évaluation a échoué. Réessayez.';

  @override
  String get evalCreateClosedPeriodError =>
      'Période clôturée : impossible d\'y ajouter une évaluation.';

  @override
  String get evalCreateMaxReachedError =>
      'Plafond de saisie atteint pour cette date.';

  @override
  String get evalRejectionPeriodClosed => 'Rejetée : période clôturée';

  @override
  String get evalRejectionExamNotAllowed => 'Rejetée : examen non autorisé';

  @override
  String get evalRejectionMaxReached => 'Rejetée : plafond atteint';

  @override
  String get evalRejectionGeneric => 'Rejetée par le serveur';

  @override
  String get noteRejectionUnknownEvaluation => 'Évaluation inconnue du serveur';

  @override
  String get noteRejectionPeriodeClose => 'Période close';

  @override
  String get noteRejectionInvalid => 'Note invalide';

  @override
  String get noteRejectionContextUnavailable => 'Contexte indisponible';

  @override
  String get noteRejectionGeneric => 'Rejetée par le serveur';

  @override
  String get evalDetailBack => 'Retour au cours';

  @override
  String get evalBadgeComplete => 'Clôturée';

  @override
  String evalBadgePartial(int done, int total) {
    return 'Saisie en cours · $done/$total';
  }

  @override
  String get evalBadgeUpcoming => 'À venir';

  @override
  String evalChipMax(String max) {
    return 'Maximum : $max pts';
  }

  @override
  String evalChipPoids(int poids) {
    return 'Poids : $poids';
  }

  @override
  String get evalModeTable => 'Tableau';

  @override
  String get evalModeFocus => 'Focus';

  @override
  String evalCountNotee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notées',
      one: '$count notée',
      zero: '$count notées',
    );
    return '$_temp0';
  }

  @override
  String evalCountEnAttente(int count) {
    return '$count en attente';
  }

  @override
  String evalCountAbsJust(int count) {
    return '$count abs. just.';
  }

  @override
  String evalCountAbsNonJust(int count) {
    return '$count abs. non just.';
  }

  @override
  String get evalStatutNotee => 'Notée';

  @override
  String get evalStatutEnAttente => 'En attente';

  @override
  String get evalStatutAbsJust => 'Abs. just.';

  @override
  String get evalStatutAbsNonJust => 'Abs. non just.';

  @override
  String evalNoteMaxError(String max) {
    return 'max $max';
  }

  @override
  String get evalAbsenceJustifieTooltip => 'Absence justifiée';

  @override
  String get evalAbsenceNonJustifieTooltip => 'Absence non justifiée';

  @override
  String get evalFocusClear => 'Effacer · en attente';

  @override
  String get evalFocusPrevious => 'Précédent';

  @override
  String get evalFocusNext => 'Suivant';

  @override
  String get evalFocusLast => 'Dernier élève';

  @override
  String evalFocusPosition(int index, int total) {
    return 'Élève $index / $total';
  }

  @override
  String evalSaveCounter(int done, int total) {
    return '$done / $total saisies';
  }

  @override
  String evalSaveErrorsAlert(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes au-dessus du maximum',
      one: '1 note au-dessus du maximum',
      zero: '0 note au-dessus du maximum',
    );
    return '$_temp0';
  }

  @override
  String get evalSaveButton => 'Enregistrer les notes';

  @override
  String get evalSaveButtonSaving => 'Enregistrement…';

  @override
  String evalSaveSuccessToast(int notees, int enAttente) {
    String _temp0 = intl.Intl.pluralLogic(
      notees,
      locale: localeName,
      other: '$notees notées',
      one: '$notees notée',
      zero: '$notees notées',
    );
    return 'Notes enregistrées — $_temp0 · $enAttente en attente';
  }

  @override
  String get evalSaveErrorToast =>
      'Échec de l\'enregistrement. Vos saisies sont conservées.';

  @override
  String get evalSaisieEmptyTitle => 'Aucun élève';

  @override
  String get evalSaisieEmptyDescription =>
      'Aucun élève n\'est inscrit dans cette classe.';

  @override
  String get evalSaisieLoadingA11y => 'Chargement de la saisie des notes';

  @override
  String get evalSaisieErrorNetworkMessage =>
      'Vous semblez hors-ligne. Vérifiez votre connexion, puis réessayez.';

  @override
  String get evalSaisieErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour saisir les notes.';

  @override
  String get evalSaisieErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour saisir ces notes.';

  @override
  String get evalSaisieErrorServerMessage =>
      'Une erreur est survenue de notre côté. Réessayez dans un instant.';

  @override
  String get evalSaisieErrorUnknownMessage =>
      'Une erreur inattendue est survenue lors du chargement de la saisie.';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get home => 'Accueil';

  @override
  String accueilBannerGreeting(String firstName) {
    return 'Bonjour, $firstName';
  }

  @override
  String get accueilBannerGreetingGeneric => 'Bonjour';

  @override
  String accueilBannerSchoolLocation(String school, String locality) {
    return '$school · $locality';
  }

  @override
  String accueilBannerSchoolYear(String year) {
    return 'Année scolaire $year';
  }

  @override
  String get accueilModulesEyebrow => 'Vos modules';

  @override
  String get accueilModulesTitle => 'Où souhaitez-vous aller ?';

  @override
  String get accueilModulesIntro =>
      'Ces modules couvrent la vie de l\'école — chaque carte ouvre son tableau de bord ou ses pages.';

  @override
  String get accueilModuleInscriptionsDescription =>
      'Premières inscriptions, réinscriptions et pré-inscriptions de vos élèves.';

  @override
  String get accueilModuleFinancesDescription =>
      'Recettes, facturation et suivi du recouvrement des frais scolaires.';

  @override
  String get accueilModuleClassesDescription =>
      'Composition des classes et liste des élèves par cycle.';

  @override
  String get accueilModuleCoursDescription =>
      'Emploi du temps de la semaine et suivi de vos cours.';

  @override
  String get accueilModuleResultatsDescription =>
      'Pourcentages par période, par classe entière ou pour un élève précis.';

  @override
  String get accueilModuleDisciplinesDescription =>
      'Présences du jour, dossiers de discipline et suivi des élèves.';

  @override
  String get accueilModuleConfigurationDescription =>
      'Identité de l\'école, structure des cycles et niveaux, grille des frais scolaires.';

  @override
  String accueilModulePageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String accueilModuleCardSemantics(String module, String page) {
    return '$module — ouvrir $page';
  }

  @override
  String accueilSubModuleSemantics(String module, String page) {
    return '$page — module $module';
  }

  @override
  String get accueilSignature => 'eteyelo · l\'école en lingala';

  @override
  String get homeTopBarPendingSubtitle => 'Suivi des dossiers en attente';

  @override
  String get homeTopBarNotificationsTooltip => 'Notifications';

  @override
  String get homeUserMenuTooltip => 'Menu utilisateur';

  @override
  String get homeSidebarCollapseTooltip => 'Replier le menu';

  @override
  String get homeSidebarExpandTooltip => 'Étendre le menu';

  @override
  String get homeOpenNavigationDrawerTooltip => 'Ouvrir le menu';

  @override
  String get homeSidebarFooterLabel => 'Tableau de bord scolaire';

  @override
  String get homeSidebarNavigationLabel => 'Navigation principale';

  @override
  String get pageUnderConstruction =>
      'Cette page est en cours de développement';

  @override
  String get preRegistrations => 'Pré-Inscriptions';

  @override
  String get searchStudents => 'Rechercher des élèves';

  @override
  String get searchFormSubtitleFirstRegistration =>
      'Filtrez la liste des inscriptions';

  @override
  String get reRegistrationSearchHint =>
      'Retrouvez un élève ou une classe de l\'année précédente à réinscrire';

  @override
  String get reRegistrationSearchTitle => 'Rechercher un élève';

  @override
  String get reRegistrationSearchLevelPlaceholder => 'Choisissez un cycle';

  @override
  String get reRegistrationAcademicInfoHelp =>
      'Sélectionnez le cycle et le niveau ciblés pour filtrer les résultats.';

  @override
  String get reRegistrationSearchNoOptions =>
      'Aucun niveau/cycle disponible pour la recherche.';

  @override
  String get reRegistrationSearchNeedCriteria =>
      'Renseignez soit Prénom, Nom et Post-nom, soit Cycle/Niveau.';

  @override
  String get reRegistrationSearchReady =>
      'Critères valides, vous pouvez lancer la recherche.';

  @override
  String get reRegistrationSearchInvitationTitle =>
      'Lancez une recherche de re-inscription';

  @override
  String get reRegistrationSearchInvitationMessage =>
      'Remplissez le formulaire ci-dessus puis cliquez sur Rechercher pour afficher les dossiers.';

  @override
  String get preRegistrationSearchHint =>
      'Retrouvez une pré-inscription par élève ou par cycle/niveau souhaité';

  @override
  String get preRegistrationSearchTitle => 'Rechercher une pré-inscription';

  @override
  String get preRegistrationSearchLevelPlaceholder => 'Choisissez un cycle';

  @override
  String get preRegistrationSearchInvitationTitle =>
      'Lancez une recherche de pré-inscription';

  @override
  String get preRegistrationSearchInvitationMessage =>
      'Remplissez le formulaire ci-dessus puis cliquez sur Rechercher pour afficher les demandes.';

  @override
  String get firstRegistrationSearchLevelPlaceholder => 'Choisissez un cycle';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get surname => 'Post-nom';

  @override
  String get dateOfBirth => 'Date de Naissance';

  @override
  String get search => 'Rechercher';

  @override
  String get clear => 'Effacer';

  @override
  String get searchModeSwitchLabel => 'Rechercher par';

  @override
  String get searchModeSemantics => 'Mode de recherche';

  @override
  String get searchModeByClass => 'Par classe';

  @override
  String get searchModeByIdentity => 'Par identité';

  @override
  String get searchModeClassHint =>
      'Choisissez un cycle puis un niveau pour lister toute la classe ; un nom, même partiel, y restreint la liste. Pour retrouver un élève sans connaître sa classe, basculez sur « Par identité ».';

  @override
  String get searchModeIdentityHint =>
      'Renseignez le nom, le post-nom et le prénom de l\'élève. Pour lister toute une classe, basculez sur « Par classe ».';

  @override
  String get searchRefineByNameLabel => 'Affiner par nom (facultatif)';

  @override
  String get searchRefineByNamePlaceholder => 'Nom de l\'élève, même partiel';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get editEnrollment => 'Modifier';

  @override
  String get exportData => 'Exporter';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get enrollmentNoResultsDescription =>
      'Aucun élève ne correspond à vos critères de recherche.';

  @override
  String get enrollmentEmptyTitle => 'Aucun résultat';

  @override
  String get enrollmentEmptyDescription =>
      'Aucune inscription ne correspond à ces critères. Ajustez votre recherche, ou créez la fiche si l\'élève n\'est pas encore enregistré.';

  @override
  String get enrollmentEmptyWithoutFilterDescription =>
      'Aucune inscription pour le moment.';

  @override
  String get enrollmentEmptyCreateAction => 'Inscrire un nouvel élève';

  @override
  String get enrollmentErrorRetry => 'Réessayer';

  @override
  String get enrollmentErrorReconnect => 'Se reconnecter';

  @override
  String get enrollmentErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String get enrollmentErrorNetworkTitle => 'Pas de connexion';

  @override
  String get enrollmentErrorNetworkMessage =>
      'Vous semblez hors-ligne. Vérifiez votre connexion internet, puis relancez.';

  @override
  String get enrollmentErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get enrollmentErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour continuer.';

  @override
  String get enrollmentErrorForbiddenTitle => 'Accès refusé';

  @override
  String get enrollmentErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour voir cette liste.';

  @override
  String get enrollmentErrorServerTitle => 'Erreur du serveur';

  @override
  String get enrollmentErrorServerMessage =>
      'Une erreur est survenue de notre côté. Réessayez dans un instant.';

  @override
  String enrollmentErrorIncidentCode(String code) {
    return 'Code incident : $code';
  }

  @override
  String get enrollmentErrorUnknownTitle => 'Chargement impossible';

  @override
  String get enrollmentErrorUnknownMessage =>
      'Une erreur inattendue est survenue lors du chargement des résultats.';

  @override
  String get loadingStudents => 'Chargement des étudiants...';

  @override
  String enrollmentResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: '0 résultat',
    );
    return '$_temp0';
  }

  @override
  String paginationPageIndicator(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String paginationResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: '0 résultat',
    );
    return '$_temp0';
  }

  @override
  String paginationRange(int start, int end, int total, String unit) {
    return '$start–$end sur $total $unit';
  }

  @override
  String get paginationNavigationLabel => 'Pagination';

  @override
  String get unitStudents => 'élèves';

  @override
  String enrollmentResultCardOpenLabel(String name, String status) {
    return 'Ouvrir la fiche de $name, statut $status';
  }

  @override
  String get refresh => 'Actualiser';

  @override
  String get statusPending => 'En Attente';

  @override
  String get statusValidated => 'Validé';

  @override
  String get statusRejected => 'Rejeté';

  @override
  String get enrollmentCode => 'Code d\'Inscription';

  @override
  String get enrollmentDetailTitle => 'Dossier d\'inscription';

  @override
  String get enrollmentUnknownStudent => 'Élève non renseigné';

  @override
  String get firstRegistrationNewEnrollmentAction => 'Nouvelle inscription';

  @override
  String get enrollmentDetailLoadingTitle => 'Chargement du dossier';

  @override
  String get enrollmentDetailLoadingMessage =>
      'Veuillez patienter pendant la récupération des informations.';

  @override
  String get enrollmentDetailLoadErrorTitle =>
      'Impossible de charger le dossier';

  @override
  String get enrollmentDetailRetryAction => 'Réessayer';

  @override
  String get gender => 'Genre';

  @override
  String get actions => 'Actions';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get address => 'Adresse';

  @override
  String get previousYear => 'Année Précédente';

  @override
  String get targetYear => 'Année Cible';

  @override
  String get guardianInformation => 'Informations des tuteurs';

  @override
  String get guardianAddAction => 'Ajouter un tuteur/responsable';

  @override
  String get guardianSaveAction => 'Enregistrer';

  @override
  String get guardianRelationshipLabel => 'Relation';

  @override
  String get guardianMarkAsPrimary => 'Désigner comme tuteur principal';

  @override
  String get guardianPrimaryRequiredHint =>
      'Au moins un tuteur principal est requis';

  @override
  String get guardianPrincipalBadge => 'Principal';

  @override
  String get guardianToggleCard => 'Ouvrir ou fermer la carte tuteur';

  @override
  String get guardianIncompleteHint => 'Fiche incomplète';

  @override
  String get guardianEmailOptionalInline => '(facultatif)';

  @override
  String get guardianDeleteAction => 'Supprimer ce tuteur';

  @override
  String get guardianDeleteConfirmTitle => 'Confirmer la suppression';

  @override
  String get guardianDeleteConfirmMessage =>
      'Voulez-vous vraiment supprimer ce tuteur ? Cette action est irréversible.';

  @override
  String get guardianDeleteConfirmAction => 'Supprimer';

  @override
  String get guardianUnlinkSuccess => 'Tuteur supprimé avec succès.';

  @override
  String guardianUnlinkError(String message) {
    return 'Erreur lors de la suppression du tuteur : $message';
  }

  @override
  String get guardianSearchDialogTitle => 'Rechercher un parent existant';

  @override
  String get guardianSearchDialogEyebrow => 'Tuteurs';

  @override
  String get guardianSearchModeSemantics => 'Mode de recherche';

  @override
  String get guardianSearchModeByPhone => 'Par numéro';

  @override
  String get guardianSearchModeByIdentity => 'Par identité';

  @override
  String get guardianSearchPhoneHint =>
      'Le numéro suffit, même partiel : « 8169 » remonte tous les tuteurs concernés.';

  @override
  String get guardianSearchIdentityHint =>
      'Nom et prénom sont requis. Le postnom affine la recherche s\'il est connu.';

  @override
  String get guardianSearchResultsPlaceholder =>
      'Les tuteurs correspondants s\'afficheront ici.';

  @override
  String get guardianSearchEmptyTitle => 'Aucun parent trouvé';

  @override
  String get guardianSearchEmptyDescription =>
      'Aucun parent ne correspond à ces critères. Vérifiez la saisie ou ajoutez-le comme nouveau tuteur.';

  @override
  String get guardianSearchAlreadyAddedError =>
      'Ce parent est déjà ajouté à cette inscription.';

  @override
  String get guardianSearchIdentityLockedHint =>
      'Informations issues d\'une fiche existante — non modifiables ici.';

  @override
  String get guardianSearchErrorRetry => 'Réessayer';

  @override
  String get guardianLinkExistingBannerTitle =>
      'Ce tuteur est déjà enregistré à l\'école ?';

  @override
  String get guardianLinkExistingBannerDescription =>
      'Retrouvez sa fiche au lieu de la ressaisir : elle remplacera ce que porte cette carte.';

  @override
  String get guardianLinkExistingAction => 'Rechercher une fiche';

  @override
  String get guardianPhoneConflictDialogEyebrow => 'Tuteurs';

  @override
  String get guardianPhoneConflictDialogTitle => 'Ce numéro est déjà utilisé';

  @override
  String guardianPhoneConflictDialogMessage(String phoneNumber) {
    return '$phoneNumber appartient déjà à une fiche existante. Rattachez-la à l\'élève, ou corrigez le numéro saisi.';
  }

  @override
  String get guardianPhoneConflictUseAction => 'Utiliser cette fiche';

  @override
  String get guardianPhoneConflictFixPhoneAction => 'Corriger le numéro';

  @override
  String get guardianPhoneConflictNotFoundTitle => 'Fiche introuvable';

  @override
  String get guardianPhoneConflictNotFoundDescription =>
      'Aucune fiche portant ce numéro n\'a pu être retrouvée. Corrigez le numéro saisi.';

  @override
  String get guardianPhoneDuplicateInFormError =>
      'Ce numéro est déjà saisi pour un autre tuteur de ce dossier.';

  @override
  String get guardianLinkTargetGoneError =>
      'Ce tuteur n\'est plus dans le dossier : la fiche n\'a pas été rattachée.';

  @override
  String get schoolFees => 'Frais Scolaires';

  @override
  String get summary => 'Résumé';

  @override
  String get summaryYes => 'Oui';

  @override
  String get summaryNo => 'Non';

  @override
  String get summaryChargesTotalDue => 'Total à régler';

  @override
  String get summaryChargesUnavailable =>
      'Montants indisponibles pour le moment.';

  @override
  String get summaryValidationNoticeTitle => 'Avant validation';

  @override
  String get summaryValidationNoticeBody =>
      'Vous certifiez que les informations sont exactes. Le dossier passera au statut validé et un reçu pourra être généré.';

  @override
  String get nextPage => 'Page suivante';

  @override
  String get previousPage => 'Page précédente';

  @override
  String get finish => 'Terminer';

  @override
  String get personalInfoSubtitle => 'Informations personnelles modifiables';

  @override
  String get firstNameHelp => 'Le prénom officiel de l\'élève.';

  @override
  String get lastNameHelp => 'Le nom de famille de l\'élève.';

  @override
  String get surnameHelp => 'Le postnom ou autre nom usuel.';

  @override
  String get dateOfBirthHelp =>
      'Utiliser le sélecteur pour choisir la date de naissance.';

  @override
  String get birthPlace => 'Lieu de naissance';

  @override
  String get birthPlaceHelp => 'Ville ou localité de naissance.';

  @override
  String get nationality => 'Nationalité';

  @override
  String get nationalityHelp => 'Nationalité principale de l\'élève.';

  @override
  String get genderHelp => 'Sexe renseigné pour le dossier administratif.';

  @override
  String get selectDateOfBirthHelpText => 'Sélectionner une date de naissance';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String enterFieldHint(String label) {
    return 'Saisir $label';
  }

  @override
  String get firstNameExample => 'Claudine';

  @override
  String get lastNameExample => 'Furah';

  @override
  String get surnameExample => 'Sifiwe';

  @override
  String get selectPlaceholderChoose => 'Choisir';

  @override
  String get requiredSemanticSuffix => 'obligatoire';

  @override
  String get dateHint => 'jj/mm/aaaa';

  @override
  String get genderMale => 'Masculin';

  @override
  String get genderFemale => 'Féminin';

  @override
  String get city => 'Ville';

  @override
  String get cityHelp => 'Ville de résidence de l\'élève.';

  @override
  String get district => 'District';

  @override
  String get districtHelp => 'District ou arrondissement.';

  @override
  String get municipality => 'Commune';

  @override
  String get municipalityHelp => 'Commune de résidence de l\'élève.';

  @override
  String get neighborhood => 'Quartier';

  @override
  String get neighborhoodHelp => 'Quartier ou avenue de résidence.';

  @override
  String get addressComplementary => 'Adresse complémentaire';

  @override
  String get addressComplementaryHelp =>
      'Précisez rue, avenue et numéro si nécessaire.';

  @override
  String get addressComplementaryPlaceholder => 'Ex: 10, Avenue La source';

  @override
  String get fullAddress => 'Adresse complète';

  @override
  String get fullAddressHelp => 'Adresse complète de résidence.';

  @override
  String get academicYearLabel => 'Année scolaire';

  @override
  String get academicYearLabelHelp => 'Année scolaire de référence.';

  @override
  String get schoolLabel => 'École';

  @override
  String get schoolLabelHelp => 'Nom de l\'école précédente.';

  @override
  String get schoolCycle => 'Cycle';

  @override
  String get schoolCycleHelp => 'Cycle d\'enseignement précédent.';

  @override
  String get schoolLevelLabel => 'Niveau';

  @override
  String get schoolLevelLabelHelp => 'Niveau d\'étude précédent.';

  @override
  String get averageLabel => 'Moyenne';

  @override
  String get averageLabelHelp => 'Moyenne annuelle obtenue.';

  @override
  String get rankingLabel => 'Classement';

  @override
  String get rankingLabelHelp => 'Classement dans la classe.';

  @override
  String get yearValidated => 'Année validée';

  @override
  String get yearValidatedHelp =>
      'Indique si l\'élève a validé son année scolaire précédente.';

  @override
  String get yearNotValidated => 'Non validée';

  @override
  String get currentAcademicYearLabel => 'Année académique';

  @override
  String get currentAcademicYearHelp => 'Année académique cible.';

  @override
  String get targetCycleLabel => 'Cycle souhaité';

  @override
  String get targetCycleLabelHelp => 'Cycle souhaité pour l\'inscription.';

  @override
  String get targetLevelLabel => 'Niveau souhaité';

  @override
  String get targetLevelLabelHelp => 'Niveau souhaité pour l\'inscription.';

  @override
  String get targetLevelAutoBadge => 'Auto';

  @override
  String get targetLevelAutoBadgeHelp =>
      'Classe calculée automatiquement depuis la classe de l\'année précédente. Modifiez le cycle ou le niveau pour la remplacer.';

  @override
  String get optionLabel => 'Option';

  @override
  String get optionLabelHelp => 'Option ou spécialisation souhaitée.';

  @override
  String get toDefine => 'À définir';

  @override
  String get primaryGuardian => 'Tuteur Principal';

  @override
  String guardianNumber(int number) {
    return 'Tuteur $number';
  }

  @override
  String get noGuardianInfo => 'Aucune information de tuteur disponible';

  @override
  String get identificationNumberLabel => 'Numéro d\'identification';

  @override
  String get identificationNumberHelp => 'Numéro d\'identification officiel.';

  @override
  String get phoneNumberLabel => 'Téléphone';

  @override
  String get phoneNumberHelp => 'Numéro de téléphone du tuteur.';

  @override
  String get phoneNumberCountryCodeLabel => 'Indicatif pays';

  @override
  String phoneNumberInvalidError(int expectedDigits) {
    return 'Numéro de téléphone invalide ($expectedDigits chiffres attendus après l\'indicatif).';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get emailLabelHelp => 'Adresse email du tuteur.';

  @override
  String get relationshipFather => 'Père';

  @override
  String get relationshipMother => 'Mère';

  @override
  String get relationshipGuardian => 'Tuteur';

  @override
  String get relationshipUncle => 'Oncle';

  @override
  String get relationshipAunt => 'Tante';

  @override
  String get relationshipGrandparent => 'Grand-parent';

  @override
  String get relationshipOther => 'Autre';

  @override
  String get stepPersonalInfoSubtitle => 'Informations générales de l\'élève';

  @override
  String get stepAddressSubtitle => 'Localisation et adresse complète';

  @override
  String get stepAddressTitle => 'Adresse de l\'élève';

  @override
  String get stepAcademicSubtitle => 'Historique académique et objectifs';

  @override
  String get stepAcademicPreviousSubtitle =>
      'Historique académique de l\'année précédente';

  @override
  String get stepAcademicTargetSubtitle =>
      'Objectifs académiques pour l\'année cible';

  @override
  String get stepGuardianSubtitle => 'Responsables légaux et contacts';

  @override
  String get stepSummarySubtitle => 'Récapitulatif final du dossier';

  @override
  String get wizardStepShortPersonal => 'Identité';

  @override
  String get wizardStepShortAddress => 'Adresse';

  @override
  String get wizardStepShortPrevious => 'Année préc';

  @override
  String get wizardStepShortTarget => 'Année cible';

  @override
  String get wizardStepShortCharges => 'Frais';

  @override
  String get wizardStepShortGuardian => 'Tuteurs';

  @override
  String get wizardStepShortSummary => 'Résumé';

  @override
  String stepIndicator(int current, int total) {
    return 'Étape $current / $total';
  }

  @override
  String wizardStepNumberShort(int number) {
    return 'Étape $number';
  }

  @override
  String get stepForwardHint =>
      'Cliquez sur Continuer pour avancer étape par étape.';

  @override
  String get journeyModeNew => 'Nouvelle';

  @override
  String get journeyModeEdit => 'Modification';

  @override
  String get journeyModeView => 'Consultation';

  @override
  String get journeyCloseAction => 'Fermer';

  @override
  String get wizardExitConfirmTitle => 'Quitter l\'inscription ?';

  @override
  String get wizardExitConfirmMessage =>
      'Une inscription est en cours. Les modifications non enregistrées de l\'étape actuelle seront perdues ; les étapes déjà enregistrées restent disponibles en brouillon.';

  @override
  String get wizardExitConfirmAction => 'Quitter';

  @override
  String get wizardExitStayAction => 'Continuer la saisie';

  @override
  String get enrollmentFinalizeConfirmTitle => 'Valider l\'inscription ?';

  @override
  String get enrollmentFinalizeConfirmMessage =>
      'Cette action confirme le dossier et le place en file de synchronisation. Vérifiez le récapitulatif avant de valider.';

  @override
  String get enrollmentFinalizeProcessingTitle =>
      'Validation de l\'inscription…';

  @override
  String get enrollmentFinalizeSuccessTitle => 'Inscription validée';

  @override
  String get enrollmentFinalizeErrorTitle => 'Échec de la validation';

  @override
  String get enrollmentFinalizeRetryAction => 'Réessayer';

  @override
  String get enrollmentFinalizeCloseAction => 'Fermer';

  @override
  String get enrollmentFinalizeContinueAction => 'Continuer';

  @override
  String get stepSaveStateIdle => 'Aucune saisie';

  @override
  String get stepSaveStateIncomplete => 'Champs incomplets';

  @override
  String get stepSaveStatePending => 'Modifications non enregistrées';

  @override
  String get stepSaveStateSaving => 'Enregistrement en cours...';

  @override
  String get stepSaveStateSaved => 'Étape enregistrée';

  @override
  String get validatePersonalInfoHint =>
      'Veuillez compléter les informations personnelles.';

  @override
  String get validateAddressHint =>
      'Veuillez compléter l\'adresse de l\'élève.';

  @override
  String get validateAcademicInfoHint =>
      'Veuillez compléter les informations académiques.';

  @override
  String get validateGuardianInfoHint =>
      'Veuillez vérifier les informations du/des tuteur(s).';

  @override
  String get enrollmentReadyForValidation =>
      'Dossier prêt pour validation finale.';

  @override
  String get completedEnrollmentRedirecting =>
      'Ce dossier est déjà complété. Redirection vers Première Inscription.';

  @override
  String get validateEnrollment => 'Valider l\'inscription';

  @override
  String get validatingEnrollment => 'Validation en cours...';

  @override
  String get goToFirstRegistration => 'Retourner à la première inscription';

  @override
  String get personalInfoSaveHintBeforeContinue =>
      'Veuillez enregistrer vos modifications avant de continuer.';

  @override
  String get personalInfoValidationReasonsTitle =>
      'Veuillez corriger les champs suivants :';

  @override
  String requiredFieldError(String field) {
    return 'Le champ $field est requis.';
  }

  @override
  String invalidNumberFieldError(String field) {
    return 'Le champ $field doit contenir un nombre valide.';
  }

  @override
  String get savePersonalInfo => 'Enregistrer les informations personnelles';

  @override
  String get savingPersonalInfo => 'Enregistrement en cours...';

  @override
  String get personalInfoSaveSuccess =>
      'Informations personnelles mises à jour avec succès.';

  @override
  String personalInfoSaveError(String message) {
    return 'Erreur lors de la mise à jour : $message';
  }

  @override
  String get saveAddress => 'Enregistrer l\'adresse';

  @override
  String get savingAddress => 'Enregistrement de l\'adresse...';

  @override
  String get saveAcademicInfo => 'Enregistrer les informations académiques';

  @override
  String get savingAcademicInfo => 'Enregistrement en cours...';

  @override
  String get saveGuardianInfo => 'Enregistrer le tuteur';

  @override
  String get savingGuardianInfo => 'Enregistrement du tuteur...';

  @override
  String get academicInfoValidationReasonsTitle =>
      'Veuillez corriger les champs académiques suivants :';

  @override
  String get academicInfoSaveHintBeforeContinue =>
      'Veuillez enregistrer les modifications académiques avant de continuer.';

  @override
  String get academicInfoSaveSuccess =>
      'Informations académiques mises à jour avec succès.';

  @override
  String academicInfoSaveError(String message) {
    return 'Erreur lors de la mise à jour des informations académiques : $message';
  }

  @override
  String get addressValidationReasonsTitle =>
      'Veuillez corriger les informations d\'adresse suivantes :';

  @override
  String get addressNoCityAvailable =>
      'Aucune ville disponible dans le catalogue.';

  @override
  String get addressSelectCityFirst => 'Sélectionnez d\'abord une ville.';

  @override
  String get addressNoDistrictAvailable =>
      'Aucun district disponible pour cette ville.';

  @override
  String get addressSelectDistrictFirst => 'Sélectionnez d\'abord un district.';

  @override
  String get addressNoMunicipalityAvailable =>
      'Aucune commune disponible pour ce district.';

  @override
  String get addressSelectMunicipalityFirst =>
      'Sélectionnez d\'abord une commune.';

  @override
  String get addressNoNeighborhoodAvailable =>
      'Aucun quartier disponible pour cette commune.';

  @override
  String get addressSaveHintBeforeContinue =>
      'Veuillez enregistrer les modifications d\'adresse avant de continuer.';

  @override
  String get addressSaveSuccess => 'Adresse mise à jour avec succès.';

  @override
  String addressSaveError(String message) {
    return 'Erreur lors de la mise à jour de l\'adresse : $message';
  }

  @override
  String get enrollmentStudentColumnLabel => 'Eleve';

  @override
  String get enrollmentStatusFilterLabel => 'Statut';

  @override
  String get enrollmentStatusInProgress => 'En cours';

  @override
  String get enrollmentDraftBadge => 'Brouillon';

  @override
  String get enrollmentTypeReEnrollment => 'Réinscription';

  @override
  String get enrollmentReenrollmentCandidateBadge => 'À réinscrire';

  @override
  String get enrollmentReRegisteredBadge => 'Réinscrit';

  @override
  String get enrollmentStatusAdminCompleted => 'Complété (Administratif)';

  @override
  String get enrollmentStatusFinancialCompleted => 'Complété (Financier)';

  @override
  String get enrollmentStatusCompleted => 'Complété';

  @override
  String get enrollmentStatusValidated => 'Validé';

  @override
  String get enrollmentStatusRejected => 'Rejeté';

  @override
  String get enrollmentStatusCancelled => 'Annulé';

  @override
  String get enrollmentReadOnlyTitle => 'Mode consultation';

  @override
  String get enrollmentReadOnlyMessage =>
      'Élève déjà inscrit — dossier consultable mais non modifiable. Parcourez les étapes pour vérifier les informations.';

  @override
  String get enrollmentEditableTitle => 'Mode édition';

  @override
  String get enrollmentEditableMessage =>
      'Ce dossier est en cours (IN_PROGRESS). Les informations peuvent être modifiées.';

  @override
  String get studentChargesStepTitle => 'Frais de l\'élève';

  @override
  String get studentChargesStepSubtitle =>
      'Montants financiers appliqués à l\'élève';

  @override
  String get studentChargesLoading => 'Chargement des charges de l\'élève...';

  @override
  String get studentChargesRetry => 'Réessayer';

  @override
  String get studentChargesEmpty => 'Aucune charge disponible pour cet élève.';

  @override
  String get studentChargesFeeGridUnavailable =>
      'La grille tarifaire n\'est pas disponible sur cet appareil pour cette année. Synchronisez avant de poursuivre.';

  @override
  String get studentChargesTariffsWithheld =>
      'Les frais ne peuvent pas être calculés : votre compte n\'a pas accès à la grille tarifaire. Demandez à un compte habilité de synchroniser cet appareil.';

  @override
  String get studentChargesUnavailable =>
      'Impossible de charger les charges sans élève ou niveau cible.';

  @override
  String get studentChargesAmountColumn => 'Montant';

  @override
  String get studentChargesLabelColumn => 'Libellé';

  @override
  String get studentChargesActionsColumn => 'Actions';

  @override
  String get studentChargesAmountPaidLabel => 'Montant payé';

  @override
  String get studentChargesSaveAction => 'Enregistrer les charges';

  @override
  String get studentChargesSavingAction => 'Enregistrement des charges...';

  @override
  String get studentChargesSaveSuccess => 'Charges enregistrées avec succès.';

  @override
  String get studentChargesSaveHintBeforeContinue =>
      'Veuillez enregistrer les modifications des charges avant de continuer.';

  @override
  String get studentChargesTotalLabel => 'Total';

  @override
  String get studentChargesHelperText =>
      'Les montants peuvent être modifiés ultérieurement depuis la fiche de l\'élève.';

  @override
  String get studentChargesNetworkError =>
      'Impossible de charger les charges. Vérifiez votre connexion internet.';

  @override
  String get studentChargesNotFound => 'Aucune charge trouvée pour cet élève.';

  @override
  String get studentChargesValidationError =>
      'Les informations de charges demandées sont invalides.';

  @override
  String get studentChargesUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces charges.';

  @override
  String get studentChargesInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux charges.';

  @override
  String get studentChargesServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get studentChargesStorageError =>
      'Une erreur locale empêche l\'affichage des charges.';

  @override
  String get studentChargesAuthError =>
      'Une erreur d\'authentification empêche le chargement des charges.';

  @override
  String get studentChargesUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des charges.';

  @override
  String get studentChargeStatusDue => 'À régler';

  @override
  String get studentChargeStatusPartial => 'Partiel';

  @override
  String get studentChargeStatusPaid => 'Payé';

  @override
  String get studentChargeFeeCodeTuition => 'Frais de scolarité';

  @override
  String get studentChargeFeeCodeRegistration => 'Frais d\'inscription';

  @override
  String get studentChargeFeeCodeEnrollment => 'Frais d\'enrôlement';

  @override
  String get studentChargeFeeCodeApplication => 'Frais de dossier';

  @override
  String get studentChargeFeeCodeAdmission => 'Frais d\'admission';

  @override
  String get studentChargeFeeCodeCanteen => 'Cantine';

  @override
  String get studentChargeFeeCodeTransport => 'Transport';

  @override
  String get studentChargeFeeCodeBoarding => 'Internat';

  @override
  String get studentChargeFeeCodeBooks => 'Livres et matériels';

  @override
  String get studentChargeFeeCodeUniform => 'Uniforme';

  @override
  String get studentChargeFeeCodeExamination => 'Frais d\'examen';

  @override
  String get studentChargeFeeCodeLabFee => 'Frais de laboratoire';

  @override
  String get studentChargeFeeCodeActivity => 'Frais d\'activités';

  @override
  String get studentChargeFeeCodeSports => 'Frais de sport';

  @override
  String get studentChargeFeeCodeLibrary => 'Frais de bibliothèque';

  @override
  String get studentChargeFeeCodeTechnology =>
      'Frais technologie / informatique';

  @override
  String get studentChargeFeeCodeDevelopment =>
      'Frais de développement / infrastructure';

  @override
  String get studentChargeFeeCodeInsurance => 'Assurance';

  @override
  String get studentChargeFeeCodeSecurityDeposit => 'Caution';

  @override
  String get studentChargeFeeCodeProcessingFee => 'Frais de traitement';

  @override
  String get studentChargeFeeCodeLatePaymentFee => 'Pénalité de retard';

  @override
  String get studentChargeFeeCodeRefund => 'Remboursement';

  @override
  String get studentChargeFeeCodeOther => 'Autre';

  @override
  String studentChargeDueAtLabel(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Échéance : $dateString';
  }

  @override
  String get studentChargeFeeCodeFallback => 'Frais scolaire';

  @override
  String get facturationSearchTitle => 'Rechercher les élèves';

  @override
  String get facturationSearchHint =>
      'Renseignez le Prénom, Nom et Post-nom et/ou le Cycle/Niveau pour filtrer les résultats.';

  @override
  String get facturationSearchInvitationTitle => 'Aucune recherche en cours';

  @override
  String get facturationSearchInvitationMessage =>
      'Saisissez un nom ou un niveau ci-dessus pour afficher les élèves correspondants.';

  @override
  String get facturationViewChargesLabel => 'Voir les charges';

  @override
  String get facturationActionsColumnLabel => 'Actions';

  @override
  String get facturationNoResultsDescription =>
      'Aucun élève ne correspond à ces critères. Modifiez le formulaire et relancez la recherche.';

  @override
  String get facturationEmptyEnrollmentWithheld =>
      'La liste des élèves relève du module Inscription, auquel ce profil n\'a pas accès : aucun élève ne peut être affiché ici, quels que soient les critères. Votre administrateur peut ouvrir cet accès.';

  @override
  String get facturationEmptyTitle => 'Aucun élève trouvé';

  @override
  String get facturationSearchHelpBanner =>
      'Recherchez toute une classe (cycle + niveau), ou un élève précis (nom + post-nom + prénom).';

  @override
  String get facturationSearchCycleLabel => 'Cycle';

  @override
  String get facturationSearchLevelLabel => 'Niveau';

  @override
  String get facturationSearchLevelPlaceholder => 'Choisissez un cycle';

  @override
  String get feeControlSearchTitle => 'Contrôler un frais';

  @override
  String get feeControlSearchHelpBanner =>
      'Choisissez la classe puis le frais à contrôler. Le statut de paiement porte sur ce frais uniquement.';

  @override
  String get feeControlSearchClassGroupTitle => 'Classe et frais';

  @override
  String get feeControlSearchStudentGroupTitle => 'Affiner par élève';

  @override
  String get feeControlSearchStudentGroupHint => 'Facultatif';

  @override
  String get feeControlSearchCycleLabel => 'Cycle';

  @override
  String get feeControlSearchLevelLabel => 'Niveau';

  @override
  String get feeControlSearchLevelPlaceholder => 'Choisissez un cycle';

  @override
  String get feeControlClassroomLabel => 'Classe';

  @override
  String get feeControlClassroomPlaceholder => 'Choisissez un niveau';

  @override
  String get feeControlClassroomAll => 'Toutes les classes du niveau';

  @override
  String get feeControlClassroomEmptyForLevel =>
      'Aucune classe n\'est composée pour ce niveau : le contrôle porte sur tout le niveau.';

  @override
  String get feeControlClassroomWithheld =>
      'Les classes relèvent d\'un module auquel ce profil n\'a pas accès : le contrôle porte sur tout le niveau.';

  @override
  String get feeControlFeeLabel => 'Frais';

  @override
  String get feeControlFeePlaceholder => 'Choisissez un niveau';

  @override
  String get feeControlFeeEmptyForLevel =>
      'Aucun frais n\'est défini pour ce niveau.';

  @override
  String get feeControlFeeGridMissing =>
      'La grille tarifaire n\'est pas encore descendue sur cet appareil. Synchronisez pour pouvoir contrôler un frais.';

  @override
  String get feeControlFeeGridWithheld =>
      'La grille tarifaire relève d\'un module auquel ce profil n\'a pas accès : elle ne descendra pas sur cet appareil, quelle que soit la synchronisation. Votre administrateur peut ouvrir cet accès.';

  @override
  String get feeControlFeeLoadFailed =>
      'La liste des frais de ce niveau n\'a pas pu être lue sur cet appareil. Réessayez ; si le problème persiste, fermez puis rouvrez l\'application.';

  @override
  String get feeControlFeeLoadRetry => 'Réessayer';

  @override
  String get feeControlPaymentStatusLabel => 'Statut de paiement';

  @override
  String get feeControlPaymentStatusAll => 'Tous';

  @override
  String get feeControlViewDetailLabel => 'Voir la fiche financière';

  @override
  String get feeControlSummaryA11yLabel => 'Synthèse du contrôle des frais';

  @override
  String get feeControlSummaryStudents => 'Élèves concernés';

  @override
  String get feeControlInvitationTitle => 'Aucun contrôle en cours';

  @override
  String get feeControlInvitationMessage =>
      'Choisissez une classe puis un frais ci-dessus pour voir qui l\'a réglé.';

  @override
  String get feeControlEmptyTitle => 'Aucun élève trouvé';

  @override
  String get feeControlNoResultsDescription =>
      'Aucun élève ne correspond à ces critères. Modifiez le formulaire et relancez la recherche.';

  @override
  String get feeControlEmptyEnrollmentWithheld =>
      'Les élèves relèvent du module Inscription, auquel ce profil n\'a pas accès : le contrôle ne peut porter sur personne, quels que soient les critères. Votre administrateur peut ouvrir cet accès.';

  @override
  String get feeControlEmptyClassroomWithheld =>
      'La composition des classes relève d\'un module auquel ce profil n\'a pas accès : le contrôle par classe est impossible. Relancez sans filtrer par classe pour porter sur tout le niveau.';

  @override
  String get feeControlEmptyRosterMissing =>
      'La liste des élèves de cette classe n\'est pas encore descendue sur cet appareil. Synchronisez, puis relancez le contrôle.';

  @override
  String get feeControlEmptyNoLocalEnrollment =>
      'Aucun élève de cette classe n\'a de dossier d\'inscription local sur cette année. Synchronisez les inscriptions, puis relancez le contrôle.';

  @override
  String get feeControlNoChargeDescription =>
      'Aucun élève de cette classe ne porte ce frais : il n\'a pas encore été généré pour eux, ou il ne s\'applique pas à ce niveau.';

  @override
  String get feeControlEmptyNoEnrollmentForLevel =>
      'Aucun élève inscrit à ce niveau sur cet appareil. Si des inscriptions viennent d\'être saisies ailleurs, synchronisez puis relancez le contrôle.';

  @override
  String get feeControlNoChargeForLevelDescription =>
      'Aucun élève de ce niveau ne porte ce frais : il n\'a pas encore été généré pour eux, ou il ne leur est pas applicable.';

  @override
  String feeControlCriteriaFee(String label) {
    return 'Frais : $label';
  }

  @override
  String feeControlCriteriaClassroom(String label) {
    return 'Classe : $label';
  }

  @override
  String feeControlCriteriaStatus(String label) {
    return 'Statut : $label';
  }

  @override
  String facturationBalanceDuePill(String amount) {
    return '$amount dû';
  }

  @override
  String get facturationBalanceUpToDatePill => 'À jour';

  @override
  String get financePendingSyncBadge => 'En attente de synchro';

  @override
  String facturationFreshnessAt(String time) {
    return 'Grand-livre à jour à $time';
  }

  @override
  String get facturationFreshnessNever => 'Grand-livre non synchronisé';

  @override
  String facturationChargeLineRemainingSuffix(String amount) {
    return '$amount restant';
  }

  @override
  String facturationPaymentRecordedToast(String amount) {
    return 'Paiement de $amount enregistré';
  }

  @override
  String get facturationChargeStatementCopied =>
      'Relevé copié dans le presse-papiers';

  @override
  String get facturationChargeStatementEmpty =>
      'Aucun paiement à exporter pour ce frais.';

  @override
  String get facturationCsvHeaderFee => 'Frais';

  @override
  String get facturationCsvHeaderImputedAmount => 'Montant imputé (USD)';

  @override
  String get facturationDetailBackLabel => 'Retour aux facturations';

  @override
  String get facturationDetailContextErrorTitle =>
      'Contexte de détail indisponible';

  @override
  String get facturationDetailContextErrorMessage =>
      'Les informations nécessaires pour afficher ce détail ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get facturationDetailUnknownValue => '-';

  @override
  String get facturationDetailStudentSectionTitle => 'Informations de l\'élève';

  @override
  String get facturationDetailStudentLastName => 'Nom';

  @override
  String get facturationDetailStudentFirstName => 'Prénom';

  @override
  String get facturationDetailStudentSurname => 'Post-nom';

  @override
  String get facturationDetailStudentLevelGroup => 'Cycle';

  @override
  String get facturationDetailStudentLevel => 'Niveau';

  @override
  String get facturationDetailInfoTitle => 'Fiche financière';

  @override
  String get facturationDetailEyebrow => 'Facturation';

  @override
  String get facturationDetailInfoSubtitle =>
      'Consultez les paiements récents et l\'état des charges de l\'élève.';

  @override
  String get facturationDetailHeaderKpiTotalDue => 'Total dû';

  @override
  String get facturationDetailHeaderKpiAlreadyPaid => 'Déjà payé';

  @override
  String get facturationDetailHeaderKpiRemaining => 'Reste à payer';

  @override
  String get facturationDetailInfoChipPayments => 'Paiements';

  @override
  String get facturationDetailInfoChipCharges => 'Charges';

  @override
  String get facturationDetailPaymentsSectionTitle => 'Derniers paiements';

  @override
  String get facturationDetailPaymentsSectionSubtitle =>
      'Historique des encaissements enregistrés pour cet élève.';

  @override
  String facturationDetailPaymentsRecordedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements enregistrés',
      one: '1 paiement enregistré',
      zero: 'Aucun paiement enregistré',
    );
    return '$_temp0';
  }

  @override
  String facturationDetailPaymentsRecordedWithTotal(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versements · $total',
      one: '1 versement · $total',
      zero: 'Aucun versement enregistré',
    );
    return '$_temp0';
  }

  @override
  String get facturationPaymentMethodCash => 'Espèces';

  @override
  String get facturationDetailCollectPaymentAction => 'Encaisser un paiement';

  @override
  String get facturationDetailPaymentsRetry => 'Réessayer';

  @override
  String get facturationDetailPaymentsEmpty =>
      'Aucun paiement n\'a été enregistré pour cet élève.';

  @override
  String get facturationDetailPaymentsWithheldSubtitle =>
      'Suivi tenu par la caisse.';

  @override
  String get facturationDetailPaymentsWithheld =>
      'Le détail des encaissements relève de la caisse : il n\'est pas affiché sur ce profil. Le total déjà payé, en haut de la fiche, reste exact.';

  @override
  String get facturationDetailPaymentPayerColumn => 'Payeur';

  @override
  String get facturationDetailPaymentPaidAtColumn => 'Date';

  @override
  String get facturationDetailPaymentAmountColumn => 'Montant';

  @override
  String get facturationDetailPaymentActionsColumn => 'Actions';

  @override
  String get facturationDetailViewPaymentLabel => 'Voir le détail du paiement';

  @override
  String get facturationDetailViewChargeLabel => 'Voir le détail de la charge';

  @override
  String get facturationPaymentDetailHeroTitle => 'Détail du paiement';

  @override
  String get facturationPaymentDetailHeroSubtitle =>
      'Consultez les informations de ce paiement et la répartition des montants alloués.';

  @override
  String get facturationPaymentInfoSectionTitle => 'Informations du paiement';

  @override
  String get facturationPaymentPayerLabel => 'Payeur';

  @override
  String get facturationPaymentAmountLabel => 'Montant global payé';

  @override
  String get facturationPaymentPaidAtLabel => 'Date de paiement';

  @override
  String get facturationPaymentAmountPaidLabel => 'Montant versé';

  @override
  String get facturationPaymentMethodLabel => 'Moyen de paiement';

  @override
  String get facturationPaymentCollectedByLabel => 'Encaissé par';

  @override
  String get facturationPaymentTicketNotPrinted => 'Ticket non imprimé';

  @override
  String get facturationPaymentPrintTicketAction => 'Imprimer maintenant';

  @override
  String get facturationPaymentReceiptLabel => 'Reçu n°';

  @override
  String get facturationPaymentStudentLabel => 'Élève';

  @override
  String get facturationPaymentDownloadReceiptLabel => 'Télécharger le reçu';

  @override
  String get facturationPaymentReceiptForbiddenHint =>
      'Vous n\'avez pas le droit d\'émettre cette pièce.';

  @override
  String get facturationPaymentReceiptPendingSyncHint =>
      'Le reçu sera disponible une fois le paiement synchronisé.';

  @override
  String get facturationPaymentReceiptNumberPending =>
      'En attente de synchronisation';

  @override
  String get facturationPaymentCloseLabel => 'Fermer';

  @override
  String get facturationPaymentAllocationsSectionTitle =>
      'Répartition par frais';

  @override
  String get facturationPaymentAllocationsSectionSubtitle =>
      'Liste des charges couvertes par ce paiement.';

  @override
  String get facturationPaymentAllocationsTotalLabel => 'Total alloué';

  @override
  String get facturationPaymentAllocationsEmpty =>
      'Aucune allocation n\'a été trouvée pour ce paiement.';

  @override
  String get facturationPaymentAllocationsConsistencyOk =>
      'La somme des allocations est cohérente avec le montant global payé.';

  @override
  String get facturationPaymentAllocationsConsistencyWarning =>
      'Incohérence détectée : la somme des allocations ne correspond pas au montant global payé.';

  @override
  String get facturationPaymentAllocationsNetworkError =>
      'Impossible de charger les allocations du paiement. Vérifiez votre connexion internet.';

  @override
  String get facturationPaymentAllocationsNotFound =>
      'Aucune allocation trouvée pour ce paiement.';

  @override
  String get facturationPaymentAllocationsValidationError =>
      'Les informations demandées pour les allocations sont invalides.';

  @override
  String get facturationPaymentAllocationsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter les allocations de ce paiement.';

  @override
  String get facturationPaymentAllocationsInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux allocations de ce paiement.';

  @override
  String get facturationPaymentAllocationsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get facturationPaymentAllocationsStorageError =>
      'Une erreur locale empêche l\'affichage des allocations.';

  @override
  String get facturationPaymentAllocationsAuthError =>
      'Une erreur d\'authentification empêche le chargement des allocations.';

  @override
  String get facturationPaymentAllocationsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des allocations.';

  @override
  String get facturationDetailChargesSectionTitle => 'Frais de l\'élève';

  @override
  String get facturationDetailChargesSectionSubtitle =>
      'Répartition des montants attendus, payés et restants.';

  @override
  String facturationDetailChargesSummary(
    num totalCount,
    Object partialCount,
    Object dueCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      totalCount,
      locale: localeName,
      other: '$totalCount charges',
      one: '1 charge',
      zero: '0 charge',
    );
    return '$_temp0 · $partialCount partielle(s), $dueCount à régler';
  }

  @override
  String get facturationDetailChargesRetry => 'Réessayer';

  @override
  String get facturationDetailChargesEmpty =>
      'Aucune charge n\'a été trouvée pour cet élève.';

  @override
  String get facturationDetailChargeLabelColumn => 'Libellé';

  @override
  String get facturationDetailChargeExpectedAmountColumn => 'Attendu';

  @override
  String get facturationDetailChargePaidAmountColumn => 'Payé';

  @override
  String get facturationDetailChargeRemainingAmountColumn => 'Reste';

  @override
  String get facturationDetailChargeStatusColumn => 'Statut';

  @override
  String get facturationDetailChargeTotalsLabel => 'Totaux';

  @override
  String get facturationPaymentsNetworkError =>
      'Impossible de charger les paiements. Vérifiez votre connexion internet.';

  @override
  String get facturationPaymentsNotFound =>
      'Aucun paiement trouvé pour cet élève.';

  @override
  String get facturationPaymentsValidationError =>
      'Les informations demandées pour les paiements sont invalides.';

  @override
  String get facturationPaymentsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces paiements.';

  @override
  String get facturationPaymentsInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux paiements.';

  @override
  String get facturationPaymentsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get facturationPaymentsStorageError =>
      'Une erreur locale empêche l\'affichage des paiements.';

  @override
  String get facturationPaymentsAuthError =>
      'Une erreur d\'authentification empêche le chargement des paiements.';

  @override
  String get facturationPaymentsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des paiements.';

  @override
  String get facturationPrintReceiptLabel => 'Imprimer le reçu';

  @override
  String get facturationPrintReceiptSubtitle =>
      'Générez et téléchargez le reçu de ce paiement';

  @override
  String get facturationPaymentDownloadPdfLabel => 'Télécharger le PDF';

  @override
  String get facturationPrintStatementsLabel => 'Imprimer les relevés';

  @override
  String get facturationPrintStatementsSubtitle =>
      'Générez et téléchargez les relevés de facturation de cet étudiant';

  @override
  String get facturationChargeDetailBackLabel =>
      'Retour au détail de facturation';

  @override
  String get facturationChargeDetailHeroTitle => 'Détail du frais';

  @override
  String get facturationChargeDetailHeroSubtitle =>
      'Consultez l\'état de cette charge et les paiements qui y ont été alloués.';

  @override
  String get facturationChargeDetailInfoSectionTitle =>
      'Informations de la charge';

  @override
  String get facturationChargeDetailExpectedAmountLabel => 'Montant attendu';

  @override
  String get facturationChargeDetailPaidAmountLabel => 'Montant payé';

  @override
  String get facturationChargeDetailRemainingAmountLabel => 'Reste à payer';

  @override
  String get facturationChargeDetailStatusLabel => 'Statut';

  @override
  String get facturationChargeDetailAllocationsSectionTitle =>
      'Paiements affectés';

  @override
  String get facturationChargeDetailAllocationsSectionSubtitle =>
      'Détail des paiements alloués à cette charge.';

  @override
  String get facturationChargeDetailAllocationLabelColumn => 'Allocation';

  @override
  String get facturationChargeDetailAllocationsTotalLabel => 'Total alloué';

  @override
  String get facturationChargeDetailAllocationsEmpty =>
      'Aucune allocation n\'a été trouvée pour cette charge.';

  @override
  String get facturationChargeDetailAllocationsWithheld =>
      'L\'imputation des versements relève de la caisse : elle n\'est pas détaillée sur ce profil. Le montant déjà payé, ci-dessus, reste exact.';

  @override
  String get facturationChargeDetailAllocationsRetry => 'Réessayer';

  @override
  String get facturationChargeDetailAllocationsNetworkError =>
      'Impossible de charger les allocations. Vérifiez votre connexion internet.';

  @override
  String get facturationChargeDetailAllocationsNotFound =>
      'Aucune allocation trouvée pour cette charge.';

  @override
  String get facturationChargeDetailAllocationsValidationError =>
      'Les informations demandées pour les allocations sont invalides.';

  @override
  String get facturationChargeDetailAllocationsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter les allocations de cette charge.';

  @override
  String get facturationChargeDetailAllocationsInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux allocations de cette charge.';

  @override
  String get facturationChargeDetailAllocationsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get facturationChargeDetailAllocationsStorageError =>
      'Une erreur locale empêche l\'affichage des allocations.';

  @override
  String get facturationChargeDetailAllocationsAuthError =>
      'Une erreur d\'authentification empêche le chargement des allocations.';

  @override
  String get facturationChargeDetailAllocationsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des allocations.';

  @override
  String get facturationChargeDetailContextErrorTitle =>
      'Contexte de détail de charge indisponible';

  @override
  String get facturationChargeDetailContextErrorMessage =>
      'Les informations nécessaires pour afficher cette charge ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get facturationCreatePaymentBackLabel =>
      'Retour au détail de facturation';

  @override
  String get facturationCreatePaymentHeroTitle => 'Nouveau paiement';

  @override
  String get facturationCreatePaymentHeroSubtitle =>
      'Renseignez les informations du payeur et les allocations pour enregistrer un paiement.';

  @override
  String get facturationCreatePaymentPayerSectionTitle =>
      'Informations du payeur';

  @override
  String get facturationCreatePaymentPayerLastNameLabel => 'Nom';

  @override
  String get facturationCreatePaymentPayerLastNameHint => 'Entrez le nom';

  @override
  String get facturationCreatePaymentPayerFirstNameLabel => 'Prénom';

  @override
  String get facturationCreatePaymentPayerFirstNameHint => 'Entrez le prénom';

  @override
  String get facturationCreatePaymentPayerMiddleNameLabel =>
      'Post-nom (optionnel)';

  @override
  String get facturationCreatePaymentPayerMiddleNameHint =>
      'Entrez le post-nom';

  @override
  String get facturationCreatePaymentPayerFieldRequired =>
      'Ce champ est obligatoire';

  @override
  String get facturationCreatePaymentPayerPhoneLabel => 'Téléphone du payeur';

  @override
  String get facturationCreatePaymentPayerPickAction => 'Choisir un payeur';

  @override
  String get facturationCreatePaymentPayerPickHelp =>
      'Reprenez un payeur déjà venu à la caisse, ou saisissez-le ci-dessous.';

  @override
  String get facturationPayerSearchDialogEyebrow => 'Encaissement';

  @override
  String get facturationPayerSearchDialogTitle => 'Choisir un payeur';

  @override
  String get facturationPayerSearchModeSemantics => 'Mode de recherche';

  @override
  String get facturationPayerSearchModeByPhone => 'Par numéro';

  @override
  String get facturationPayerSearchModeByIdentity => 'Par identité';

  @override
  String get facturationPayerSearchPhoneHint =>
      'Le numéro suffit, même partiel : « 8169 » remonte tous les payeurs concernés.';

  @override
  String get facturationPayerSearchIdentityHint =>
      'Un seul mot suffit — nom, post-nom ou prénom. Les accents sont ignorés.';

  @override
  String get facturationPayerSearchAction => 'Rechercher';

  @override
  String get facturationPayerSearchSuggestionsTitle =>
      'Déjà connus pour cet élève';

  @override
  String get facturationPayerSearchResultsTitle => 'Résultats';

  @override
  String get facturationPayerSearchResultsPlaceholder =>
      'Les payeurs correspondants s\'afficheront ici.';

  @override
  String get facturationPayerSearchEmptyTitle => 'Aucun payeur trouvé';

  @override
  String get facturationPayerSearchEmptyDescription =>
      'Aucun payeur ne correspond à ces critères. Vérifiez la saisie, ou fermez cette fenêtre pour le saisir à la main.';

  @override
  String get facturationPayerSearchErrorRetry => 'Réessayer';

  @override
  String get facturationPayerSearchOriginGuardian =>
      'Tuteur de l\'élève — n\'a encore rien payé';

  @override
  String facturationPayerSearchPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versements',
      one: '1 versement',
    );
    return '$_temp0';
  }

  @override
  String facturationPayerSearchLastPaidAt(String date) {
    return 'dernier le $date';
  }

  @override
  String get facturationPayerSearchUnknownPhone => 'Numéro inconnu';

  @override
  String facturationPayerSearchSelectSemantics(String name) {
    return 'Choisir $name comme payeur';
  }

  @override
  String get facturationCreatePaymentDetailsSectionTitle =>
      'Détails du paiement';

  @override
  String get facturationCreatePaymentDetailsSectionSubtitle =>
      'Saisissez le montant reçu, la devise et la date du paiement.';

  @override
  String get facturationCreatePaymentReceivedAmountLabel => 'Montant reçu';

  @override
  String get facturationCreatePaymentReceivedAmountHint => 'Ex : 200';

  @override
  String get facturationCreatePaymentCurrencyLabel => 'Devise';

  @override
  String get facturationCreatePaymentCurrencyReadOnlyHint =>
      'Plusieurs devises détectées : valeur en lecture seule.';

  @override
  String get facturationCreatePaymentCurrencyUnavailable =>
      'Devise indisponible';

  @override
  String get facturationCreatePaymentDateLabel => 'Date du paiement';

  @override
  String get facturationCreatePaymentAllocationSectionTitle =>
      'Allocations de paiement';

  @override
  String get facturationCreatePaymentAllocationSectionSubtitle =>
      'Associez un montant à une ou plusieurs charges de l\'élève.';

  @override
  String get facturationCreatePaymentAddAllocationLabel =>
      'Ajouter une allocation';

  @override
  String get facturationCreatePaymentAllChargesPaid =>
      'Toutes les charges de cet élève sont déjà réglées.';

  @override
  String get facturationCreatePaymentChargesUnavailable =>
      'Aucune charge disponible. Revenez à la liste et recommencez.';

  @override
  String get facturationCollectPreflightMessage =>
      'Vérification des encaissements récents…';

  @override
  String get facturationCreatePaymentChargeDropdownHint =>
      'Sélectionnez une charge';

  @override
  String get facturationCreatePaymentAmountLabel => 'Montant à payer';

  @override
  String get facturationCreatePaymentAmountHint => 'Ex : 5000';

  @override
  String get facturationCreatePaymentAmountRequired =>
      'Le montant est obligatoire';

  @override
  String get facturationCreatePaymentAmountInvalid =>
      'Veuillez entrer un nombre valide';

  @override
  String get facturationCreatePaymentAmountExceedsRemaining =>
      'Le montant ne peut pas dépasser le restant à payer';

  @override
  String get facturationCreatePaymentAmountMustBePositive =>
      'Le montant doit être supérieur à zéro';

  @override
  String get facturationCreatePaymentBeforeLabel => 'Avant paiement';

  @override
  String get facturationCreatePaymentAfterLabel => 'Après paiement';

  @override
  String get facturationCreatePaymentRemoveAllocationConfirmTitle =>
      'Confirmer la suppression';

  @override
  String facturationCreatePaymentRemoveAllocationConfirmMessage(
    int allocationIndex,
  ) {
    return 'Voulez-vous vraiment supprimer l\'allocation n° $allocationIndex ? Cette action est irréversible.';
  }

  @override
  String get facturationCreatePaymentRemoveAllocationConfirmAction =>
      'Supprimer';

  @override
  String get facturationCreatePaymentSubmitLabel => 'Valider le paiement';

  @override
  String get facturationCreatePaymentNoAllocations =>
      'Ajoutez au moins une allocation pour valider le paiement.';

  @override
  String get facturationCreatePaymentConfirmTitle => 'Confirmer le paiement';

  @override
  String get facturationCreatePaymentConfirmMessage =>
      'Cette opération est irréversible. Confirmez-vous l\'enregistrement de ce paiement ?';

  @override
  String get facturationCreatePaymentConfirmCancel => 'Annuler';

  @override
  String get facturationCreatePaymentConfirmValidate => 'Confirmer';

  @override
  String get facturationCreatePaymentCloseConfirmTitle =>
      'Fermer l\'encaissement ?';

  @override
  String get facturationCreatePaymentCloseConfirmMessage =>
      'Les informations saisies seront perdues si vous fermez maintenant.';

  @override
  String get facturationCreatePaymentCloseConfirmAction => 'Fermer';

  @override
  String get facturationCreatePaymentCloseConfirmCancel =>
      'Continuer la saisie';

  @override
  String get facturationCreatePaymentSuccessMessage =>
      'Paiement enregistré avec succès.';

  @override
  String get facturationCreatePaymentExpectedLabel => 'Montant attendu';

  @override
  String get facturationCreatePaymentPaidLabel => 'Déjà payé';

  @override
  String get facturationCreatePaymentRemainingLabel => 'Restant';

  @override
  String get facturationCreatePaymentStatusLabel => 'Statut';

  @override
  String get facturationCreatePaymentChargeImpactTitle =>
      'Impact sur la charge';

  @override
  String facturationCreatePaymentChargeRemainingHelper(String remainingAmount) {
    return 'Restant sur cette charge : $remainingAmount';
  }

  @override
  String get facturationCreatePaymentPayAllAction => 'Tout payer';

  @override
  String get facturationCreatePaymentDistributionTrackerIdle =>
      'Saisissez au moins une allocation pour calculer le total paiements.';

  @override
  String facturationCreatePaymentFooterTotalPayments(String allocatedAmount) {
    return 'Total paiements : $allocatedAmount';
  }

  @override
  String get facturationCreatePaymentNetworkError =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get facturationCreatePaymentNotFoundError =>
      'La ressource demandée est introuvable.';

  @override
  String get facturationCreatePaymentValidationError =>
      'Les données saisies sont invalides. Vérifiez le formulaire.';

  @override
  String get facturationCreatePaymentUnauthorizedError =>
      'Vous n\'êtes pas autorisé à effectuer cette opération.';

  @override
  String get facturationCreatePaymentInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'enregistrer ce paiement.';

  @override
  String get facturationCreatePaymentServerError =>
      'Le serveur est indisponible. Réessayez plus tard.';

  @override
  String get facturationCreatePaymentStorageError =>
      'Une erreur de stockage est survenue.';

  @override
  String get facturationCreatePaymentAuthError =>
      'Une erreur d\'authentification est survenue.';

  @override
  String get facturationCreatePaymentUnknownError =>
      'Une erreur inattendue est survenue.';

  @override
  String get facturationCreatePaymentNoChargesAvailable =>
      'Aucune charge non réglée disponible pour cet élève.';

  @override
  String get facturationCreatePaymentChargesToSettleTitle => 'Frais à régler';

  @override
  String get facturationCreatePaymentChargesToSettleSubtitle =>
      'Cochez les frais à régler et ajustez les montants.';

  @override
  String get facturationCreatePaymentAllFeesSettled =>
      'Tous les frais sont déjà soldés.';

  @override
  String facturationCreatePaymentChargeDue(String amount) {
    return 'Dû $amount';
  }

  @override
  String facturationCreatePaymentChargePaid(String amount) {
    return 'Déjà payé $amount';
  }

  @override
  String facturationCreatePaymentChargeRemaining(String amount) {
    return 'Restant $amount';
  }

  @override
  String get facturationCreatePaymentAmountToSettleLabel => 'Montant à régler';

  @override
  String get facturationCreatePaymentSettleAllAction => 'Tout solder';

  @override
  String facturationCreatePaymentAmountClampedWarning(String amount) {
    return 'Montant ramené au restant dû ($amount).';
  }

  @override
  String facturationCreatePaymentRemainingAfter(String amount) {
    return 'Restant après : $amount';
  }

  @override
  String get facturationCreatePaymentSettledChip => 'Soldé';

  @override
  String get facturationCreatePaymentTotalToCollect => 'Total à encaisser';

  @override
  String facturationCreatePaymentCollectAmountAction(String amount) {
    return 'Encaisser $amount';
  }

  @override
  String facturationCreatePaymentConfirmCollectTitle(String amount) {
    return 'Encaisser $amount ?';
  }

  @override
  String facturationCreatePaymentConfirmSentence(
    String amount,
    String student,
    String payer,
  ) {
    return 'Vous allez encaisser $amount pour $student, réglé par $payer.';
  }

  @override
  String get facturationCreatePaymentConfirmDistributionTitle => 'Répartition';

  @override
  String get facturationCollectStepConfirm => 'Confirmation';

  @override
  String get facturationCollectStepResult => 'Résultat';

  @override
  String get facturationCollectSimulateFailure => 'Simuler un échec';

  @override
  String get facturationCollectProcessing => 'Enregistrement du paiement…';

  @override
  String get facturationCollectSuccessTitle => 'Paiement enregistré';

  @override
  String facturationCollectReceiptChip(String code) {
    return 'Reçu n° $code';
  }

  @override
  String get facturationCollectErrorTitle => 'Échec de l\'encaissement';

  @override
  String get facturationCollectErrorNoDebit => 'Aucun montant n\'a été débité.';

  @override
  String facturationCollectIncidentChip(String code) {
    return 'Code incident : $code';
  }

  @override
  String get facturationCollectEditAction => 'Modifier';

  @override
  String get facturationCollectRetryAction => 'Réessayer';

  @override
  String get attendanceHeroTitle => 'Présences';

  @override
  String get attendanceHeroSubtitle =>
      'Consultez les présences par classe et date pour un suivi quotidien fiable.';

  @override
  String get attendanceHeroChipClass => 'Recherche par classe';

  @override
  String get attendanceHeroChipDate => 'Filtre par date';

  @override
  String get attendanceSearchTitle => 'Recherche des présences';

  @override
  String get attendanceSearchHint =>
      'Sélectionnez cycle, niveau, classe et date pour afficher les enregistrements.';

  @override
  String get attendanceDateLabel => 'Date';

  @override
  String get attendanceCycleLabel => 'Cycle';

  @override
  String get attendanceLevelLabel => 'Niveau';

  @override
  String get attendanceClassLabel => 'Classe';

  @override
  String get attendanceShowClassAction => 'Afficher la classe';

  @override
  String get attendanceInvitationMessage =>
      'Lancez une recherche pour afficher les présences de la classe sélectionnée.';

  @override
  String get attendanceSelectClassTitle => 'Sélectionnez une classe';

  @override
  String get attendanceEmptySelectionMessage =>
      'Choisissez un cycle, un niveau puis une classe pour charger la liste d\'appel.';

  @override
  String get attendanceLoadingMessage => 'Chargement des présences en cours...';

  @override
  String get attendanceEmptyStudentsTitle => 'Aucun élève dans cette classe';

  @override
  String get attendanceEmptyStudentsDescription =>
      'Cette classe ne contient encore aucun élève. Ajoutez des élèves depuis la Composition des classes pour pouvoir faire l\'appel.';

  @override
  String get attendanceEmptyOpenComposition => 'Ouvrir la Composition';

  @override
  String get attendanceExportAction => 'Exporter';

  @override
  String get attendanceExportTooltip => 'Préparer l\'export des résultats';

  @override
  String get attendanceExportSoon => 'L\'export sera disponible prochainement.';

  @override
  String get attendanceSaveAction => 'Enregistrer';

  @override
  String get attendanceSavingAction => 'Enregistrement...';

  @override
  String get attendanceSaveTooltip =>
      'Enregistrer toutes les modifications saisies';

  @override
  String get attendanceSaveValidationHint =>
      'Corrigez les lignes absentes sans motif avant d\'enregistrer.';

  @override
  String get attendanceSaveSuccess =>
      'Les présences ont été enregistrées avec succès.';

  @override
  String get attendanceValidateCallAction => 'Valider l\'appel';

  @override
  String get attendancePendingChanges => 'Modifications en attente';

  @override
  String get attendancePendingInvalidChanges => 'Corrections requises';

  @override
  String get attendanceRowModifiedLabel => 'Modifiée';

  @override
  String get attendanceUnsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get attendanceUnsavedChangesMessage =>
      'Une nouvelle recherche supprimera les changements non enregistrés. Voulez-vous continuer ?';

  @override
  String get attendanceDateTooltip => 'Choisir la date des présences';

  @override
  String get attendanceStatusInProgress => 'Appel en cours';

  @override
  String get attendanceStatusReady => 'Prêt à valider';

  @override
  String get attendancePresentCount => 'Présents';

  @override
  String get attendanceJustifiedCount => 'Justifiés';

  @override
  String get attendanceUnjustifiedCount => 'Non justifiés';

  @override
  String get attendancePendingCount => 'À motiver';

  @override
  String get attendanceAbsentCount => 'Absents';

  @override
  String get attendanceTotalCountCompact => 'Total';

  @override
  String get attendanceDefaultPresenceHelper =>
      'Tous les élèves sont présents par défaut. Tapez Absent pour signaler une exception.';

  @override
  String get attendanceReadyToValidate =>
      'Aucune absence sans motif. Vous pouvez valider l\'appel.';

  @override
  String attendanceMissingReasonsStatus(int count) {
    return '$count absence(s) sans motif — à compléter';
  }

  @override
  String get attendanceAllPresentConfirmTitle => 'Confirmer l\'appel';

  @override
  String attendanceAllPresentConfirmMessage(int count) {
    return 'Confirmez-vous que les $count élèves sont présents ?';
  }

  @override
  String get attendanceTotalCount => 'Effectif total';

  @override
  String get attendanceGirlsCount => 'Effectif filles';

  @override
  String get attendanceBoysCount => 'Effectif garçons';

  @override
  String attendanceCriteriaSummary(String classroomName, String formattedDate) {
    return 'Classe : $classroomName · Date : $formattedDate';
  }

  @override
  String get attendanceTableLastName => 'Nom';

  @override
  String get attendanceTableMiddleName => 'Post-nom';

  @override
  String get attendanceTableFirstName => 'Prénom';

  @override
  String get attendanceTablePresent => 'Présence';

  @override
  String get attendanceTableAbsenceReason => 'Motif';

  @override
  String get attendanceTableAbsenceReasonNote => 'Note';

  @override
  String get attendancePresenceStatusLabel => 'Statut de présence';

  @override
  String get attendancePresentValue => 'Présent';

  @override
  String get attendanceAbsentValue => 'Absent';

  @override
  String get attendanceReadOnlyHint => 'Statut consultatif en lecture seule';

  @override
  String get attendanceReasonRequiredError =>
      'Veuillez sélectionner un motif pour cette absence.';

  @override
  String get attendanceReasonRequiredHint => 'Motif requis pour une absence.';

  @override
  String get attendanceMotifRequisLabel => 'Motif requis';

  @override
  String get attendanceReasonDisabledHint =>
      'Le motif est requis seulement pour une absence.';

  @override
  String get attendanceNoteDisabledHint =>
      'La note est facultative seulement pour une absence.';

  @override
  String get attendanceNotePlaceholder => 'Ajouter une précision si nécessaire';

  @override
  String get attendanceNoMiddleName => 'Non renseigné';

  @override
  String get attendanceNoAbsenceReason => 'Aucun motif';

  @override
  String get attendanceNoAbsenceNote => 'Aucune note';

  @override
  String get attendanceErrorNetwork =>
      'Vérifiez votre connexion internet puis réessayez.';

  @override
  String get attendanceErrorNotFound =>
      'Aucune ressource de présence n\'a été trouvée.';

  @override
  String get attendanceErrorValidation =>
      'Les données envoyées sont invalides.';

  @override
  String get attendanceErrorUnauthorized =>
      'Vous n\'êtes pas autorisé à accéder à cette ressource.';

  @override
  String get attendanceErrorInvalidCredentials =>
      'Vos identifiants ne permettent pas d\'accéder aux présences.';

  @override
  String get attendanceErrorServer =>
      'Le serveur est indisponible. Réessayez plus tard.';

  @override
  String get attendanceErrorStorage =>
      'Une erreur de stockage local est survenue.';

  @override
  String get attendanceErrorAuth =>
      'Une erreur d\'authentification est survenue.';

  @override
  String get attendanceErrorUnknown => 'Une erreur inattendue est survenue.';

  @override
  String get attendanceErrorForbidden =>
      'Vous n\'avez pas les droits requis pour consulter les présences.';

  @override
  String get attendanceErrorRetry => 'Réessayer';

  @override
  String get attendanceErrorReconnect => 'Se reconnecter';

  @override
  String get attendanceErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String get attendanceErrorNetworkTitle => 'Pas de connexion';

  @override
  String get attendanceErrorNetworkMessage =>
      'Vous semblez hors-ligne. Vérifiez votre connexion internet, puis relancez l\'appel.';

  @override
  String get attendanceErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get attendanceErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour reprendre l\'appel.';

  @override
  String get attendanceErrorForbiddenTitle => 'Accès refusé';

  @override
  String get attendanceErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour consulter les présences de cette classe.';

  @override
  String get attendanceErrorServerTitle => 'Erreur du serveur';

  @override
  String get attendanceErrorServerMessage =>
      'Une erreur est survenue de notre côté. Réessayez dans un instant.';

  @override
  String attendanceErrorIncidentCode(String code) {
    return 'Code incident : $code';
  }

  @override
  String get attendanceErrorUnknownTitle => 'Chargement impossible';

  @override
  String get attendanceErrorUnknownMessage =>
      'Une erreur inattendue est survenue lors du chargement de l\'appel.';

  @override
  String get attendanceSaveCallAction => 'Enregistrer l\'appel';

  @override
  String get attendancePastCallAmendLocked =>
      'Cet appel a déjà été enregistré et le jour est révolu : le corriger relève de la surveillance générale, pas de la prise d\'appel.';

  @override
  String get attendanceFocusPrevious => 'Précédent';

  @override
  String get attendanceFocusNext => 'Suivant';

  @override
  String get attendanceModeList => 'Liste';

  @override
  String get attendanceModeFocus => 'Focus';

  @override
  String attendancePendingReasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count motifs à renseigner',
      one: '1 motif à renseigner',
    );
    return '$_temp0';
  }

  @override
  String get attendanceUnsupportedReasonBlocked =>
      'Une absence porte un motif que cette version de l\'application ne connaît pas. Choisissez-en un pour pouvoir enregistrer — sans quoi il serait remplacé sans que personne le voie.';

  @override
  String get attendanceMarkAllPresentAction => 'Tout présent';

  @override
  String get attendanceCallNotTakenTitle => 'Appel non fait';

  @override
  String get attendanceCallNotTakenMessage =>
      'Aucun appel n\'a encore été enregistré pour ce jour. Validez pour l\'enregistrer.';

  @override
  String get attendanceSaveOverlayEyebrow => 'Appel';

  @override
  String get attendanceSaveProcessingTitle => 'Enregistrement en cours…';

  @override
  String get attendanceSaveSuccessTitle => 'Appel enregistré !';

  @override
  String get attendanceSaveSuccessSubtitle =>
      'Les présences de la classe ont été sauvegardées.';

  @override
  String get attendanceSaveErrorTitle => 'Échec de l\'enregistrement';

  @override
  String get attendanceSaveErrorMessage =>
      'Les saisies sont conservées. Vérifiez votre connexion et réessayez.';

  @override
  String get attendanceSaveRetryAction => 'Réessayer';

  @override
  String get attendanceSaveCloseAction => 'Terminer';

  @override
  String get absenceReasonSickness => 'Maladie';

  @override
  String get absenceReasonFamilyEmergency => 'Urgence familiale';

  @override
  String get absenceReasonPersonal => 'Personnel';

  @override
  String get absenceReasonUnknown => 'Non justifiée';

  @override
  String get absenceReasonVacation => 'Vacances';

  @override
  String get absenceReasonUnderGraduateLeave => 'Congé d\'études';

  @override
  String get absenceReasonMarriageLeave => 'Congé de mariage';

  @override
  String get absenceReasonParentalLeave => 'Congé parental';

  @override
  String get absenceReasonWorkLeave => 'Congé professionnel';

  @override
  String get absenceReasonUnjustified => 'Absence non justifiée';

  @override
  String get absenceReasonOther => 'Autre';

  @override
  String get absenceReasonUnsupported => 'Motif non reconnu';

  @override
  String get bootstrapContextUnavailableTitle =>
      'Contexte d\'inscription indisponible';

  @override
  String get bootstrapContextUnavailableMessage =>
      'Les données bootstrap (année scolaire / école) sont absentes. Veuillez vous déconnecter puis vous reconnecter pour recharger la configuration.';

  @override
  String get signOutAction => 'Se déconnecter';

  @override
  String get disciplinaryDetailBackLabel => 'Retour aux disciplines';

  @override
  String get disciplinaryFollowUpTitle => 'Suivi disciplinaire';

  @override
  String get disciplinaryHeroTitle => 'Détail du dossier disciplinaire';

  @override
  String get disciplinaryHeroChipCases => 'Cas disciplinaires';

  @override
  String get disciplinaryDetailContextErrorTitle =>
      'Contexte de détail indisponible';

  @override
  String get disciplinaryDetailContextErrorMessage =>
      'Les informations nécessaires pour afficher ce détail ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get disciplinaryTabCasesLabel => 'Cas disciplinaires';

  @override
  String get disciplinaryTabAttendanceHistoryLabel => 'Historique de présences';

  @override
  String get presenceStatusPresent => 'Présent';

  @override
  String get presenceStatusJustified => 'Absence justifiée';

  @override
  String get presenceStatusUnjustified => 'Absence injustifiée';

  @override
  String get presenceSummaryTitle => 'Synthèse de présence';

  @override
  String presenceSummaryA11yLabel(int rate) {
    return 'Synthèse de présence, taux $rate %';
  }

  @override
  String get presenceKpiRate => 'Taux de présence';

  @override
  String presenceRateValue(int rate) {
    return '$rate %';
  }

  @override
  String presenceSchoolDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours scolaires',
      one: '1 jour scolaire',
      zero: '0 jour scolaire',
    );
    return '$_temp0';
  }

  @override
  String get presenceDistributionA11yLabel =>
      'Répartition des jours par statut';

  @override
  String presencePresentOutOfTotal(int present, int total) {
    return '$present jours présents sur $total';
  }

  @override
  String get presenceAbsenceListTitle => 'Détail des absences';

  @override
  String presenceAbsenceDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get presencePerfectTitle => 'Assiduité parfaite';

  @override
  String get presencePerfectMessage => 'Aucune absence sur cette période.';

  @override
  String get presenceLoadingA11yLabel =>
      'Chargement de la synthèse de présence…';

  @override
  String get presencePeriodWeek => 'Semaine';

  @override
  String get presencePeriodMonth => 'Mois';

  @override
  String get presencePeriodYear => 'Année';

  @override
  String get presencePeriodFilterA11yLabel => 'Période d\'assiduité';

  @override
  String get presenceEmptyTitle => 'Aucun jour scolaire';

  @override
  String get presenceEmptyMessage =>
      'Aucun jour scolaire sur cette période. Choisissez une autre période pour consulter l\'assiduité.';

  @override
  String presenceRangeYear(String name) {
    return 'Année scolaire $name';
  }

  @override
  String presenceRangeMonth(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String presenceRangeWeek(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Semaine du $dateString';
  }

  @override
  String get presenceOfflineSyncPendingTitle => 'Synchronisation en cours';

  @override
  String get presenceOfflineSyncPendingMessage =>
      'Les données locales de présence ne sont pas encore complètes pour calculer une statistique fiable. Réessayez dans un instant.';

  @override
  String get disciplinaryUnknownValue => '-';

  @override
  String get disciplinaryCaseCreateAction => 'Nouveau cas';

  @override
  String get disciplinaryCaseCreateCtaSubtitle =>
      'Documentez un nouvel incident disciplinaire pour cet élève.';

  @override
  String disciplinaryCasesSummary(int total, int open) {
    return '$total cas enregistrés - $open ouverts';
  }

  @override
  String get disciplinaryCasesTableTitleColumn => 'Titre';

  @override
  String get disciplinaryCasesTableStatusColumn => 'Statut';

  @override
  String get disciplinaryCasesTableActionColumn => 'Actions';

  @override
  String get disciplinaryCasesDateUnavailable => 'Date non disponible';

  @override
  String get disciplinaryCaseViewLabel => 'Voir le cas';

  @override
  String get disciplinaryCasesLoadingMessage =>
      'Chargement des cas disciplinaires...';

  @override
  String get disciplinaryCasesEmptyMessage =>
      'Aucun cas disciplinaire pour cet élève.';

  @override
  String get disciplinaryCaseViewDialogTitle => 'Détail du cas disciplinaire';

  @override
  String get disciplinaryCaseViewDialogSectionTitle => 'Informations du cas';

  @override
  String get disciplinaryCaseViewDialogTitleField => 'Titre';

  @override
  String get disciplinaryCaseViewDialogStatusField => 'Statut';

  @override
  String get disciplinaryCaseViewDialogContentField => 'Contenu';

  @override
  String get disciplinaryCaseViewDialogLoadingMessage =>
      'Chargement du détail du cas...';

  @override
  String get disciplinaryCaseViewDialogErrorMessage =>
      'Impossible de charger le détail du cas';

  @override
  String get disciplinaryCaseCreateDialogTitle => 'Créer un cas disciplinaire';

  @override
  String get disciplinaryCaseCreateDialogTitleField => 'Titre du cas';

  @override
  String get disciplinaryCaseCreateDialogTitleHint =>
      'Décrivez brièvement le cas';

  @override
  String get disciplinaryCaseCreateDialogContentField => 'Contenu';

  @override
  String get disciplinaryCaseCreateDialogContentHint =>
      'Détails du cas disciplinaire';

  @override
  String get disciplinaryCaseCreateDialogCaseDateField => 'Date du cas';

  @override
  String get disciplinaryCaseCreateDialogCaseDateHint => 'Sélectionner la date';

  @override
  String get disciplinaryCaseCreateDialogSubmitAction => 'Créer le cas';

  @override
  String get disciplinaryCaseCreateDialogCreatingMessage =>
      'Création en cours...';

  @override
  String get disciplinaryCaseCreateDialogSuccessMessage =>
      'Cas disciplinaire créé avec succès.';

  @override
  String get disciplinaryCaseCreateDialogRequiredFieldError =>
      'Ce champ est obligatoire.';

  @override
  String get disciplinaryCasesNetworkError =>
      'Vérifiez votre connexion internet puis réessayez.';

  @override
  String get disciplinaryCasesNotFound => 'Aucun cas disciplinaire trouvé.';

  @override
  String get disciplinaryCasesValidationError =>
      'Les données demandées sont invalides.';

  @override
  String get disciplinaryCasesUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces cas.';

  @override
  String get disciplinaryCasesInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux cas.';

  @override
  String get disciplinaryCasesServerError =>
      'Le serveur est indisponible. Réessayez plus tard.';

  @override
  String get disciplinaryCasesStorageError =>
      'Une erreur de stockage local est survenue.';

  @override
  String get disciplinaryCasesAuthError =>
      'Une erreur d\'authentification empêche le chargement des cas.';

  @override
  String get disciplinaryCasesUnknownError =>
      'Une erreur inattendue est survenue.';

  @override
  String get disciplinaryCaseStatusOpen => 'Ouvert';

  @override
  String get disciplinaryCaseStatusInProgress => 'En cours';

  @override
  String get disciplinaryCaseStatusClosed => 'Clôturé';

  @override
  String get disciplinaryCaseStatusUnknown => 'Inconnu';

  @override
  String get disciplinarySeverityMinor => 'Mineure';

  @override
  String get disciplinarySeverityMajor => 'Majeure';

  @override
  String get disciplinarySeveritySerious => 'Grave';

  @override
  String get disciplinarySeverityUnknown => 'Non précisée';

  @override
  String get disciplinaryCategoryDisruptiveBehavior =>
      'Comportement perturbateur';

  @override
  String get disciplinaryCategoryLateness => 'Retard';

  @override
  String get disciplinaryCategoryRepeatedLateness => 'Retard répété';

  @override
  String get disciplinaryCategoryUnjustifiedAbsence => 'Absence injustifiée';

  @override
  String get disciplinaryCategoryInsolence => 'Insolence';

  @override
  String get disciplinaryCategoryCheating => 'Tricherie';

  @override
  String get disciplinaryCategoryFighting => 'Bagarre';

  @override
  String get disciplinaryCategoryDressCodeViolation => 'Tenue non conforme';

  @override
  String get disciplinaryCategoryTalkingInClass => 'Bavardage en classe';

  @override
  String get disciplinaryCategoryUnknown => 'Autre';

  @override
  String get disciplinarySanctionOralWarning => 'Avertissement oral';

  @override
  String get disciplinarySanctionWrittenWarning => 'Avertissement écrit';

  @override
  String get disciplinarySanctionDetention => 'Retenue';

  @override
  String get disciplinarySanctionParentsSummoned => 'Convocation des parents';

  @override
  String get disciplinarySanctionTemporaryExclusion => 'Exclusion temporaire';

  @override
  String get disciplinarySanctionDisciplinaryCouncil => 'Conseil de discipline';

  @override
  String get disciplinarySanctionPermanentExclusion => 'Exclusion définitive';

  @override
  String get disciplinarySanctionUnknown => 'Aucune sanction';

  @override
  String disciplinaryCaseSeverityChip(String severity) {
    return 'Gravité $severity';
  }

  @override
  String get disciplinaryAdvanceTakeCharge => 'Prendre en charge';

  @override
  String get disciplinaryAdvanceClose => 'Clôturer';

  @override
  String get disciplinaryStatusOfflinePending => 'Pris en charge';

  @override
  String get disciplinaryStatusOfflineResolved => 'Résolu';

  @override
  String get disciplinaryStatusOfflineDismissed => 'Classé sans suite';

  @override
  String get disciplinaryAdvanceResolve => 'Résoudre';

  @override
  String get disciplinaryAdvanceDismiss => 'Classer sans suite';

  @override
  String get disciplinaryCaseResolvedLabel => 'Dossier résolu';

  @override
  String get disciplinaryCaseDismissedLabel => 'Classé sans suite';

  @override
  String get disciplinaryCaseClosedLabel => 'Dossier clôturé';

  @override
  String disciplinaryCommentsCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
      zero: '0 commentaire',
    );
    return '$_temp0';
  }

  @override
  String get disciplinaryCommentsDialogTitle => 'Commentaires';

  @override
  String get disciplinaryCommentsEmpty => 'Aucun commentaire pour l\'instant.';

  @override
  String get disciplinaryCommentAddHint => 'Ajouter un commentaire…';

  @override
  String get disciplinaryCommentAddAction => 'Ajouter';

  @override
  String get disciplinaryCommentsCloseAction => 'Fermer';

  @override
  String get disciplinaryFreshnessSynced => 'À jour';

  @override
  String get disciplinaryFreshnessLocal => 'Poste local';

  @override
  String disciplinaryCasesCountPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cas',
      one: '1 cas',
      zero: '0 cas',
    );
    return '$_temp0';
  }

  @override
  String disciplinaryCasesOpenPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ouverts',
      one: '1 ouvert',
      zero: '0 ouvert',
    );
    return '$_temp0';
  }

  @override
  String disciplinaryCasesGravePill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count graves',
      one: '1 grave',
      zero: '0 grave',
    );
    return '$_temp0';
  }

  @override
  String get disciplinaryCasesEmptyTitle => 'Aucun cas de discipline';

  @override
  String get disciplinaryCasesEmptyDescription =>
      'Aucun incident enregistré pour cet élève. Tout va bien.';

  @override
  String get disciplinaryFieldCategory => 'Catégorie';

  @override
  String get disciplinaryFieldSeverity => 'Gravité';

  @override
  String get disciplinaryFieldSanction => 'Sanction';

  @override
  String get disciplinaryStatusAtCreationLabel => 'Statut à l\'ouverture';

  @override
  String get disciplinaryStatusAtCreationHint =>
      'Le cas sera créé Ouvert. Vous le ferez ensuite évoluer depuis la fiche.';

  @override
  String get disciplinaryErrorNetworkTitle => 'Pas de connexion';

  @override
  String get disciplinaryErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get disciplinaryErrorForbiddenTitle => 'Accès refusé';

  @override
  String get disciplinaryErrorServerTitle => 'Erreur du serveur';

  @override
  String get disciplinaryErrorUnknownTitle => 'Chargement impossible';

  @override
  String get disciplinaryErrorRetry => 'Réessayer';

  @override
  String get disciplinaryErrorReconnect => 'Se reconnecter';

  @override
  String get disciplinaryErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String get enrollmentStatusPreRegistered => 'Pré-inscrit';

  @override
  String get statusPaid => 'Payé';

  @override
  String get statusPartial => 'Partiel';

  @override
  String get statusOverdue => 'En retard';

  @override
  String get statusPresent => 'Présent';

  @override
  String get statusAbsentJustified => 'Justifié';

  @override
  String get statusAbsentUnjustified => 'Absent';

  @override
  String get statusSynced => 'À jour';

  @override
  String get statusPartiallySynced => 'Partiellement à jour';

  @override
  String get statusSyncing => 'Synchro…';

  @override
  String get statusOffline => 'Hors ligne';

  @override
  String get statusPendingUpload => 'À envoyer';

  @override
  String get statusSyncConflict => 'Conflit';

  @override
  String get statusAuthRequired => 'Reconnexion requise';

  @override
  String get syncLastSyncJustNow => 'À l\'instant';

  @override
  String syncLastSyncMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count min',
      one: 'Il y a 1 min',
      zero: 'Il y a 0 min',
    );
    return '$_temp0';
  }

  @override
  String syncLastSyncHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count h',
      one: 'Il y a 1 h',
      zero: 'Il y a 0 h',
    );
    return '$_temp0';
  }

  @override
  String syncLastSyncDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count jours',
      one: 'Il y a 1 jour',
      zero: 'Il y a 0 jour',
    );
    return '$_temp0';
  }

  @override
  String get syncRowSynced => 'Synchronisé avec le serveur';

  @override
  String get syncRowPending => 'En attente de synchronisation';

  @override
  String get syncRowError =>
      'Refusée par le serveur — ne repartira pas d\'elle-même';

  @override
  String get syncErrorsTitle => 'Écritures en échec';

  @override
  String get syncErrorsSubtitle =>
      'Ces enregistrements ont été refusés par le serveur. Ils ne repartiront pas d\'eux-mêmes.';

  @override
  String get syncErrorsRetry => 'Réessayer';

  @override
  String get syncErrorsRetryAll => 'Tout réessayer';

  @override
  String get syncErrorsEmptyLabel => 'Aucune écriture en échec';

  @override
  String get syncErrorsEmptyDescription =>
      'Tout ce qui a été saisi est parti ou attend son tour.';

  @override
  String get syncErrorsLoadFailedTitle => 'Liste indisponible';

  @override
  String get syncErrorsLoadFailedMessage =>
      'Impossible de lire la file d\'envoi locale.';

  @override
  String get syncErrorsNotReplayable =>
      'Cet appel ne peut pas être renvoyé tel quel : la liste des absences a pu changer depuis. Rouvrez la journée concernée et revalidez-la.';

  @override
  String get syncErrorsClose => 'Fermer';

  @override
  String syncErrorsQueuedAt(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString à $timeString';
  }

  @override
  String get syncAggregateEnrollment => 'Inscription';

  @override
  String get syncAggregatePayment => 'Paiement';

  @override
  String get syncAggregateAttendance => 'Présence';

  @override
  String get syncAggregateDisciplinaryCase => 'Cas disciplinaire';

  @override
  String get syncAggregateNotesBatch => 'Lot de notes';

  @override
  String get syncAggregateEvaluation => 'Évaluation';

  @override
  String get syncAggregateClassroomTransfer => 'Transfert de classe';

  @override
  String get offlineQueuedGeneric =>
      'Enregistré — en attente de synchronisation';

  @override
  String get offlinePaymentQueued =>
      'Paiement enregistré — en attente de synchronisation';

  @override
  String get offlineEnrollmentQueued =>
      'Inscription enregistrée — en attente de synchronisation';

  @override
  String get offlineAttendanceQueued =>
      'Appel enregistré — en attente de synchronisation';

  @override
  String get offlineDisciplinaryCaseQueued =>
      'Cas disciplinaire enregistré — en attente de synchronisation';

  @override
  String get offlineDisciplinaryCaseUpdatedQueued =>
      'Cas mis à jour — en attente de synchronisation';

  @override
  String get offlineWriteError => 'Échec de l\'enregistrement local';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Continuer';

  @override
  String get componentGalleryTitle => 'Galerie de composants';

  @override
  String get enrollmentStatsDashboardTitle =>
      'Vue d\'ensemble – Année scolaire';

  @override
  String get enrollmentStatsPeriodYear => 'Année';

  @override
  String get enrollmentStatsPeriodMonth => 'Mois';

  @override
  String get enrollmentStatsPeriodWeek => 'Semaine';

  @override
  String get enrollmentStatsKpiTotal => 'Total';

  @override
  String get enrollmentStatsKpiFirst => 'Premières inscriptions';

  @override
  String get enrollmentStatsKpiRe => 'Réinscriptions';

  @override
  String get enrollmentStatsKpiPre => 'Pré-inscriptions';

  @override
  String get enrollmentStatsKpiInProgress => 'En cours';

  @override
  String get enrollmentStatsSectionEvolution => 'Évolution';

  @override
  String get enrollmentStatsSectionCycle => 'Par cycle';

  @override
  String get enrollmentStatsSectionGender => 'Par genre';

  @override
  String get enrollmentStatsSectionEvolutionEnrollments =>
      'Evolution des Inscritions';

  @override
  String get enrollmentStatsSectionLevelEvolution => 'Evolution par niveau';

  @override
  String get enrollmentStatsSectionGenderEvolution => 'Evolution par genre';

  @override
  String get enrollmentStatsGenderMale => 'Garçons';

  @override
  String get enrollmentStatsGenderFemale => 'Filles';

  @override
  String get enrollmentStatsGenderOther => 'Autre';

  @override
  String get enrollmentStatsNoData => 'Aucune donnée pour cette période';

  @override
  String get enrollmentStatsLoadingError =>
      'Impossible de charger les statistiques';

  @override
  String get enrollmentStatsRetry => 'Réessayer';

  @override
  String get enrollmentStatsStudents => 'élèves';

  @override
  String enrollmentStatsPercent(int percent) {
    return '$percent %';
  }

  @override
  String get enrollmentStatsPeriodWeekCurrent => 'Cette semaine';

  @override
  String get enrollmentStatsPeriodMonthCurrent => 'Ce mois';

  @override
  String get enrollmentStatsPeriodYearCurrent => 'Cette année';

  @override
  String get enrollmentStatsSchoolYearUnavailable =>
      'Année scolaire indisponible';

  @override
  String enrollmentStatsHeaderA11yLabel(String schoolYear) {
    return 'Tableau de bord des inscriptions, année scolaire $schoolYear';
  }

  @override
  String enrollmentStatsPeriodFilterA11yLabel(String selectedPeriod) {
    return 'Filtre temporel des statistiques d\'inscription, période active : $selectedPeriod';
  }

  @override
  String enrollmentStatsContextSchoolYear(String schoolYear) {
    return 'Vue d\'ensemble — Année scolaire $schoolYear';
  }

  @override
  String get classesStatsDashboardTitle =>
      'Vue d\'ensemble Classes — Année scolaire';

  @override
  String get classesStatsSchoolYearUnavailable => 'Année scolaire indisponible';

  @override
  String classesStatsHeaderA11yLabel(String schoolYear) {
    return 'Tableau de bord des classes, année scolaire $schoolYear';
  }

  @override
  String get classesStatsKpiTotalStudents => 'TOTAL ELEVES';

  @override
  String get classesStatsKpiActiveGirls => 'TOTAL FILLES';

  @override
  String get classesStatsKpiActiveBoys => 'GARCONS';

  @override
  String get classesStatsKpiInactiveStudents => 'TOTAL ELEVES INACTIFS';

  @override
  String get classesStatsSectionCycleDistribution =>
      'Répartition des actifs par cycle';

  @override
  String classesStatsSectionLevelDistribution(String cycleCode) {
    return 'Répartition des niveaux — $cycleCode';
  }

  @override
  String get classesStatsSectionClassroomDetail => 'Détail des classes';

  @override
  String get classesStatsDetailColumnClassroom => 'Classe';

  @override
  String get classesStatsDetailColumnCycle => 'Cycle';

  @override
  String get classesStatsDetailColumnLevel => 'Niveau';

  @override
  String get classesStatsDetailColumnTotal => 'Total';

  @override
  String get classesStatsDetailColumnGirls => 'Filles';

  @override
  String get classesStatsDetailColumnBoys => 'Garçons';

  @override
  String get classesStatsNoData =>
      'Aucune donnée disponible pour cette période';

  @override
  String get classesStatsKpiBandA11yLabel =>
      'Bandeau des indicateurs clés classes';

  @override
  String get classesStatsCycleChartA11yLabel =>
      'Graphique de répartition des élèves actifs par cycle';

  @override
  String classesStatsLevelChartA11yLabel(String cycleCode) {
    return 'Graphique de répartition des élèves actifs par niveau pour le cycle $cycleCode';
  }

  @override
  String get classesStatsDetailA11yLabel =>
      'Tableau détaillé des classes avec effectifs par genre';

  @override
  String get classesStatsLoadingA11yLabel =>
      'Chargement des statistiques classes en cours';

  @override
  String get classesStatsErrorTitle => 'Erreur de chargement';

  @override
  String get classesStatsRetry => 'Réessayer';

  @override
  String get classesStatsRetryHint =>
      'Relancer le chargement des statistiques classes';

  @override
  String classesStatsErrorA11yLabel(String message) {
    return 'Erreur de chargement des statistiques classes : $message';
  }

  @override
  String get classesStatsNetworkError =>
      'Impossible de charger les statistiques classes. Vérifiez votre connexion internet.';

  @override
  String get classesStatsNotFoundError =>
      'Aucune statistique classes disponible.';

  @override
  String get classesStatsValidationError =>
      'Les paramètres demandés sont invalides.';

  @override
  String get classesStatsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces statistiques.';

  @override
  String get classesStatsInvalidCredentialsError =>
      'Session invalide, reconnectez-vous.';

  @override
  String get classesStatsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get classesStatsStorageError =>
      'Une erreur locale empêche l\'affichage des statistiques.';

  @override
  String get classesStatsAuthError =>
      'Une erreur d\'authentification empêche le chargement des statistiques.';

  @override
  String get classesStatsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des statistiques.';

  @override
  String get financeStatsDashboardTitle => 'Vue d\'ensemble — Année scolaire';

  @override
  String get financeStatsSchoolYearUnavailable => 'Année scolaire indisponible';

  @override
  String financeStatsContextSchoolYear(String schoolYear) {
    return 'Vue d\'ensemble — Année scolaire $schoolYear';
  }

  @override
  String get financeStatsPeriodWeekCurrent => 'Cette semaine';

  @override
  String get financeStatsPeriodMonthCurrent => 'Ce mois';

  @override
  String get financeStatsPeriodYearCurrent => 'Cette année';

  @override
  String get financeStatsKpiCollected => 'Total encaissé';

  @override
  String get financeStatsKpiExpected => 'Total attendu';

  @override
  String get financeStatsKpiOutstanding => 'Reste à recouvrer';

  @override
  String get financeStatsKpiCollectionRate => 'Taux de recouvrement';

  @override
  String get financeStatsSectionEvolution => 'Évolution des encaissements';

  @override
  String get financeStatsLegendCurrentPeriod => 'Période en cours';

  @override
  String get financeStatsLegendOtherPeriods => 'Autres périodes';

  @override
  String get financeStatsSectionFeeTypeDistribution =>
      'Répartition par type de frais';

  @override
  String financeStatsFeeTypeCollected(String amount) {
    return 'Encaissé : $amount';
  }

  @override
  String financeStatsFeeTypeExpected(String amount) {
    return 'Attendu : $amount';
  }

  @override
  String financeStatsFeeTypeRate(int rate) {
    return 'Taux : $rate%';
  }

  @override
  String get financeStatsNoData =>
      'Aucune donnée disponible pour cette période';

  @override
  String get financeStatsNoDataHint =>
      'Essayez une autre période pour afficher davantage d\'informations.';

  @override
  String get financeStatsErrorTitle => 'Erreur de chargement';

  @override
  String get financeStatsRetry => 'Réessayer';

  @override
  String get financeStatsRetryHint =>
      'Relancer le chargement des statistiques financières';

  @override
  String get financeStatsLoadingA11yLabel =>
      'Chargement des statistiques financières en cours';

  @override
  String financeStatsHeaderA11yLabel(String schoolYear) {
    return 'Tableau de bord finance, année scolaire $schoolYear';
  }

  @override
  String financeStatsPeriodFilterA11yLabel(String selectedPeriod) {
    return 'Filtre temporel des statistiques financières, période active : $selectedPeriod';
  }

  @override
  String get financeStatsKpiBandA11yLabel =>
      'Bandeau des indicateurs clés financiers';

  @override
  String get financeStatsEvolutionChartA11yLabel =>
      'Graphique d\'évolution des montants encaissés';

  @override
  String get financeStatsFeeTypeSectionA11yLabel =>
      'Répartition des montants par type de frais';

  @override
  String financeStatsFeeTypeItemA11yLabel(
    String code,
    String collected,
    String expected,
    int rate,
  ) {
    return 'Type $code, encaissé $collected, attendu $expected, taux $rate%';
  }

  @override
  String financeStatsErrorA11yLabel(String message) {
    return 'Erreur de chargement des statistiques financières : $message';
  }

  @override
  String get financeStatsEmptyA11yLabel =>
      'Aucune donnée financière disponible pour cette période';

  @override
  String get financeStatsNetworkError =>
      'Impossible de charger les statistiques finance. Vérifiez votre connexion internet.';

  @override
  String get financeStatsNotFoundError =>
      'Aucune statistique finance disponible.';

  @override
  String get financeStatsValidationError =>
      'Les paramètres demandés sont invalides.';

  @override
  String get financeStatsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces statistiques.';

  @override
  String get financeStatsInvalidCredentialsError =>
      'Session invalide, reconnectez-vous.';

  @override
  String get financeStatsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get financeStatsStorageError =>
      'Une erreur locale empêche l\'affichage des statistiques.';

  @override
  String get financeStatsAuthError =>
      'Une erreur d\'authentification empêche le chargement des statistiques.';

  @override
  String get financeStatsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des statistiques.';

  @override
  String get enrollmentResults => 'Résultats';

  @override
  String get sort => 'Trier';

  @override
  String get switchToTableView => 'Passer à la vue tableau';

  @override
  String get switchToGridView => 'Passer à la vue grille';

  @override
  String get enrollmentViewTable => 'Tableau';

  @override
  String get enrollmentViewGrid => 'Grille';

  @override
  String get enrollmentResultsA11yLabel => 'Résultats d\'inscriptions';

  @override
  String get dataTableSortAscending => 'Tri croissant';

  @override
  String get dataTableSortDescending => 'Tri décroissant';

  @override
  String get dataTableSortNone => 'Tri non appliqué';

  @override
  String openDetailsForStudent(String studentName) {
    return 'Ouvrir la fiche de $studentName';
  }

  @override
  String removeFilterNamed(String filter) {
    return 'Retirer le filtre $filter';
  }

  @override
  String get attendanceOverviewEyebrow => 'Disciplines · Présences';

  @override
  String get attendanceOverviewTitle => 'Tableau de bord';

  @override
  String get attendanceOverviewContextSchoolYear => 'Année scolaire';

  @override
  String get attendanceOverviewContextWindow => 'Fenêtre';

  @override
  String get attendanceOverviewContextGeneratedAt => 'Généré le';

  @override
  String get attendanceOverviewContextA11yLabel =>
      'Contexte des statistiques de présence';

  @override
  String get attendanceOverviewKpiPresence => 'Taux de présence';

  @override
  String get attendanceOverviewKpiJustified => 'Absences justifiées';

  @override
  String get attendanceOverviewKpiUnjustified => 'Absences non justifiées';

  @override
  String get attendanceOverviewKpiRecordedDays => 'Jours enregistrés';

  @override
  String attendanceOverviewRateValue(String rate) {
    return '$rate %';
  }

  @override
  String attendanceOverviewStudentDays(String count) {
    return '$count élève-jours';
  }

  @override
  String get attendanceOverviewKpiBandA11yLabel =>
      'Indicateurs clés de présence';

  @override
  String get attendanceOverviewSplitTitle => 'Répartition présence / absences';

  @override
  String get attendanceOverviewSplitSumHint => 'somme = 100 %';

  @override
  String get attendanceOverviewSplitPresence => 'Présence';

  @override
  String get attendanceOverviewSplitJustified => 'Absences justifiées';

  @override
  String get attendanceOverviewSplitUnjustified => 'Absences non justifiées';

  @override
  String attendanceOverviewSplitA11yLabel(
    String presence,
    String justified,
    String unjustified,
  ) {
    return 'Présence $presence %, justifiées $justified %, non justifiées $unjustified %';
  }

  @override
  String get attendanceOverviewEvolutionTitle =>
      'Évolution du taux de présence';

  @override
  String get attendanceOverviewEvolutionHintMonth => 'par mois';

  @override
  String get attendanceOverviewEvolutionHintWeek => 'par semaine';

  @override
  String get attendanceOverviewEvolutionHintDay => 'par jour';

  @override
  String attendanceOverviewEvolutionTarget(String rate) {
    return 'Objectif $rate %';
  }

  @override
  String get attendanceOverviewReasonsTitle => 'Motifs d\'absence';

  @override
  String get attendanceOverviewReasonsHint => 'école';

  @override
  String get attendanceOverviewReasonsCenterLabel => 'absences';

  @override
  String get attendanceOverviewReasonUnjustified => 'Non justifié';

  @override
  String get attendanceOverviewReasonUnjustifiedNote => 'UNKNOWN/null';

  @override
  String get attendanceOverviewWeekdayTitle => 'Absences par jour';

  @override
  String get attendanceOverviewWeekdayHint => 'Lun → Ven';

  @override
  String get attendanceWeekdayMon => 'Lun';

  @override
  String get attendanceWeekdayTue => 'Mar';

  @override
  String get attendanceWeekdayWed => 'Mer';

  @override
  String get attendanceWeekdayThu => 'Jeu';

  @override
  String get attendanceWeekdayFri => 'Ven';

  @override
  String get attendanceOverviewTopAbsentTitle =>
      'Classes les plus absentéistes';

  @override
  String get attendanceOverviewTopAbsentHint => 'top 5';

  @override
  String get attendanceOverviewByClassTitle => 'Présence par classe';

  @override
  String get attendanceOverviewColClass => 'Classe';

  @override
  String get attendanceOverviewColLevel => 'Niveau';

  @override
  String get attendanceOverviewColPresence => 'Présence';

  @override
  String get attendanceOverviewColJustified => 'Justif.';

  @override
  String get attendanceOverviewColUnjustified => 'Non justif.';

  @override
  String get attendanceOverviewColDistribution => 'Répartition';

  @override
  String get attendanceOverviewEmptyTitle => 'Aucune donnée de présence';

  @override
  String get attendanceOverviewEmptyDescription =>
      'Aucun appel n\'a été enregistré sur la fenêtre. Les statistiques apparaîtront dès le premier appel saisi.';

  @override
  String get attendanceOverviewEmptyAction => 'Faire l\'appel';

  @override
  String get attendanceOverviewLoadingA11yLabel =>
      'Chargement du tableau de bord des présences';

  @override
  String get dossierTabsA11yLabel => 'Onglets du dossier élève';

  @override
  String get dossierTabDisciplineLabel => 'Discipline';

  @override
  String get dossierTabDisciplineDescription => 'Cas, sanctions & suivi';

  @override
  String get dossierTabPresenceLabel => 'Présence';

  @override
  String get dossierTabPresenceDescription => 'Absences & retards';

  @override
  String dossierOpenCasesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cas ouverts',
      one: '1 cas ouvert',
      zero: '0 cas ouvert',
    );
    return '$_temp0';
  }

  @override
  String get dossierNoOpenCases => 'Aucun cas ouvert';

  @override
  String get genderOther => 'Autre';

  @override
  String get scheduleErrorNoTeacher =>
      'Aucun enseignant n\'est lié à votre compte.';

  @override
  String get scheduleErrorConflict =>
      'Ce créneau est déjà occupé (enseignant ou classe).';

  @override
  String get scheduleErrorGeneric =>
      'Une erreur est survenue lors du chargement de l\'emploi du temps.';

  @override
  String get scheduleEmpty => 'Aucune séance planifiée.';

  @override
  String get scheduleEyebrow => 'Cours';

  @override
  String get scheduleTitle => 'Mon emploi du temps';

  @override
  String get scheduleViewWeek => 'Semaine';

  @override
  String get scheduleViewDay => 'Jour';

  @override
  String get scheduleViewToggleSemantics =>
      'Basculer entre la vue Semaine et la vue Jour';

  @override
  String get scheduleWeekTitle => 'Semaine type';

  @override
  String scheduleLoadSummary(int count, double hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '$count séance',
      zero: '$count séances',
    );
    return '$_temp0 · $hoursString h de cours';
  }

  @override
  String get scheduleToday => 'auj.';

  @override
  String get scheduleTodaySemantics => 'Aujourd\'hui';

  @override
  String get scheduleBreak => 'Récréation';

  @override
  String get scheduleLoadingSemantics => 'Chargement de l\'emploi du temps';

  @override
  String get scheduleEmptyDescription =>
      'Aucun créneau n\'est planifié pour vous cette semaine. L\'emploi du temps est géré par la direction des études.';

  @override
  String get scheduleEmptyDayTitle => 'Aucun cours ce jour';

  @override
  String scheduleEmptyDayDescription(String day) {
    return 'Aucune séance n\'est planifiée le $day.';
  }

  @override
  String get scheduleWeekdayLongMon => 'Lundi';

  @override
  String get scheduleWeekdayLongTue => 'Mardi';

  @override
  String get scheduleWeekdayLongWed => 'Mercredi';

  @override
  String get scheduleWeekdayLongThu => 'Jeudi';

  @override
  String get scheduleWeekdayLongFri => 'Vendredi';

  @override
  String get scheduleWeekdayLongSat => 'Samedi';

  @override
  String get scheduleWeekdayShortMon => 'Lun.';

  @override
  String get scheduleWeekdayShortTue => 'Mar.';

  @override
  String get scheduleWeekdayShortWed => 'Mer.';

  @override
  String get scheduleWeekdayShortThu => 'Jeu.';

  @override
  String get scheduleWeekdayShortFri => 'Ven.';

  @override
  String get scheduleWeekdayShortSat => 'Sam.';

  @override
  String get scheduleErrorNetworkTitle => 'Connexion interrompue';

  @override
  String get scheduleErrorNetworkMessage =>
      'Impossible de joindre le serveur. Vérifiez votre connexion, puis réessayez.';

  @override
  String get scheduleErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get scheduleErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour consulter l\'emploi du temps.';

  @override
  String get scheduleErrorForbiddenTitle => 'Accès refusé';

  @override
  String get scheduleErrorForbiddenMessage =>
      'Vous n\'avez pas les droits pour consulter cet emploi du temps. Contactez l\'administrateur.';

  @override
  String get scheduleErrorServerTitle => 'Erreur serveur';

  @override
  String get scheduleErrorServerMessage =>
      'Une erreur est survenue côté serveur. Réessayez dans un instant.';

  @override
  String get scheduleErrorUnknownTitle => 'Une erreur est survenue';

  @override
  String get scheduleErrorUnknownMessage =>
      'Impossible de charger l\'emploi du temps pour le moment. Réessayez.';

  @override
  String get scheduleErrorRetry => 'Réessayer';

  @override
  String get scheduleErrorReconnect => 'Se reconnecter';

  @override
  String get scheduleErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String scheduleErrorIncidentCode(String code) {
    return 'Code incident : $code';
  }

  @override
  String get menuResultats => 'Résultats';

  @override
  String get subMenuResultatsClasse => 'Résultats par classe';

  @override
  String get resultatsSearchEyebrow => 'Résultats';

  @override
  String get resultatsSearchTitle => 'Rechercher des résultats';

  @override
  String get resultatsSearchModeSemantics => 'Mode de recherche';

  @override
  String get resultatsSearchByClass => 'Par classe';

  @override
  String get resultatsSearchByStudent => 'Par élève';

  @override
  String get resultatsSearchActionClasse => 'Afficher les résultats';

  @override
  String get resultatsSearchActionEleve => 'Retrouver l\'élève';

  @override
  String get resultatsFieldLastName => 'Nom';

  @override
  String get resultatsFieldMiddleName => 'Postnom';

  @override
  String get resultatsFieldFirstName => 'Prénom(s)';

  @override
  String get resultatsFieldClassroom => 'Classe';

  @override
  String get resultatsDecoupageTrimestres => 'Trimestres';

  @override
  String get resultatsDecoupageSemestres => 'Semestres';

  @override
  String get resultatsDecoupagePeriodes => 'Périodes';

  @override
  String resultatsPeriodShortTrimestre(int ordre) {
    return 'T$ordre';
  }

  @override
  String resultatsPeriodShortSemestre(int ordre) {
    return 'S$ordre';
  }

  @override
  String resultatsPeriodShortGeneric(int ordre) {
    return 'P$ordre';
  }

  @override
  String resultatsPeriodLongTrimestre(int ordre) {
    return 'Trimestre $ordre';
  }

  @override
  String resultatsPeriodLongSemestre(int ordre) {
    return 'Semestre $ordre';
  }

  @override
  String resultatsPeriodLongGeneric(int ordre) {
    return 'Période $ordre';
  }

  @override
  String resultatsSubPeriodColumn(int ordre) {
    return 'P$ordre';
  }

  @override
  String get resultatsPeriodsError => 'Impossible de charger les périodes.';

  @override
  String get resultatsPeriodsEmpty => 'Aucune période disponible.';

  @override
  String get resultatsGenderMale => 'Garçon';

  @override
  String get resultatsGenderFemale => 'Fille';

  @override
  String get resultatsGenderOther => 'Autre';

  @override
  String get resultatsDash => '—';

  @override
  String resultatsPercentValue(int value) {
    return '$value %';
  }

  @override
  String resultatsNoteOverMax(String note, String max) {
    return '$note/$max';
  }

  @override
  String resultatsPlaceValue(int place, int total) {
    return '$place / $total';
  }

  @override
  String resultatsDeltaPts(String value) {
    return '$value pts';
  }

  @override
  String get resultatsColumnRank => '#';

  @override
  String get resultatsColumnEleve => 'Élève';

  @override
  String resultatsColumnMoyenne(String period) {
    return 'Moyenne $period';
  }

  @override
  String get resultatsNonClasseBadge => 'Non classé';

  @override
  String resultatsSummaryAverageCaption(String period) {
    return 'Moyenne · $period';
  }

  @override
  String resultatsSummaryReussites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réussites',
      one: '1 réussite',
      zero: '0 réussite',
    );
    return '$_temp0';
  }

  @override
  String resultatsSummaryEchecs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échecs',
      one: '1 échec',
      zero: '0 échec',
    );
    return '$_temp0';
  }

  @override
  String resultatsSummaryNonClasses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non classés',
      one: '1 non classé',
      zero: '0 non classé',
    );
    return '$_temp0';
  }

  @override
  String resultatsSummaryFootnote(int effectif, int seuil) {
    return '$effectif élèves · seuil de réussite $seuil %';
  }

  @override
  String resultatsEleveResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count élèves trouvés',
      one: '1 élève trouvé',
      zero: '0 élève trouvé',
    );
    return '$_temp0';
  }

  @override
  String resultatsFocusClassroom(String classroom) {
    return 'Classe $classroom';
  }

  @override
  String get resultatsFocusBack => 'Retour à la vue classe';

  @override
  String get resultatsFocusAnnualAverage => 'Moyenne annuelle';

  @override
  String resultatsFocusRankOf(int count) {
    return 'sur $count classés';
  }

  @override
  String get resultatsFocusNoBulletin =>
      'Élève non classé sur cette période : pas de bulletin détaillé.';

  @override
  String get resultatsProgressionTitle => 'Progression sur l\'année';

  @override
  String resultatsProgressionPointLabel(int index) {
    return 'P$index';
  }

  @override
  String get resultatsStrengthsTitle => 'Points forts';

  @override
  String get resultatsWeaknessesTitle => 'À renforcer';

  @override
  String get resultatsOfficialBulletinTitle => 'Bulletin officiel';

  @override
  String get resultatsOfficialBulletinSubtitle =>
      'Domaines & branches, notes journalières + examen, maxima, place — gabarit national imprimable.';

  @override
  String get resultatsComingSoon => 'Bientôt disponible';

  @override
  String resultatsBulletinTitle(String period) {
    return 'Bulletin par domaine · $period';
  }

  @override
  String get resultatsBulletinLegend => 'note / maximum';

  @override
  String get resultatsBulletinSubtotal => 'Sous-total';

  @override
  String get resultatsBulletinTotal => 'Totaux obtenus';

  @override
  String get resultatsSynthesePercent => 'Pourcentage';

  @override
  String get resultatsSynthesePlace => 'Place';

  @override
  String get resultatsSyntheseApplication => 'Application';

  @override
  String get resultatsSyntheseConduite => 'Conduite';

  @override
  String get resultatsIdleTitle => 'Choisissez une classe ou un élève';

  @override
  String get resultatsIdleDescription =>
      'Sélectionnez un cycle, un niveau et une classe, puis une période pour afficher les résultats.';

  @override
  String get resultatsLoadingSemantics => 'Chargement des résultats';

  @override
  String get resultatsEmptyClasse =>
      'Aucun élève à afficher pour cette classe.';

  @override
  String get resultatsEmptyClasseTitle => 'Aucun résultat pour cette classe';

  @override
  String get resultatsEmptyEleveTitle => 'Aucun élève trouvé';

  @override
  String get resultatsEmptyEleveDescription =>
      'Vérifiez l\'orthographe du nom, du postnom ou du prénom, ou élargissez la recherche.';

  @override
  String get resultatsEmptyAdjustAction => 'Ajuster la recherche';

  @override
  String get resultatsErrorRetry => 'Réessayer';

  @override
  String get resultatsErrorReconnect => 'Se reconnecter';

  @override
  String get resultatsErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String resultatsErrorIncidentCode(String code) {
    return 'Code incident : $code';
  }

  @override
  String get resultatsErrorNetworkTitle => 'Connexion interrompue';

  @override
  String get resultatsErrorNetworkMessage =>
      'Vérifiez votre connexion internet puis réessayez.';

  @override
  String get resultatsErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get resultatsErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour continuer.';

  @override
  String get resultatsErrorForbiddenTitle => 'Accès refusé';

  @override
  String get resultatsErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour consulter ces résultats.';

  @override
  String get resultatsErrorServerTitle => 'Erreur serveur';

  @override
  String get resultatsErrorServerMessage =>
      'Une erreur est survenue de notre côté. Réessayez dans un instant.';

  @override
  String get resultatsErrorUnknownTitle => 'Une erreur est survenue';

  @override
  String get resultatsErrorUnknownMessage =>
      'Un problème inattendu est survenu. Réessayez.';

  @override
  String get syncErrorsOtherAccountTitle => 'En attente d\'un autre compte';

  @override
  String syncErrorsOtherAccountNamed(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écritures en attente de $name',
      one: '$count écriture en attente de $name',
    );
    return '$_temp0';
  }

  @override
  String syncErrorsOtherAccountAnonymous(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écritures en attente d\'un autre compte',
      one: '$count écriture en attente d\'un autre compte',
    );
    return '$_temp0';
  }

  @override
  String syncErrorsOtherAccountOldest(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'la plus ancienne du $dateString';
  }

  @override
  String get syncErrorsOtherAccountHint =>
      'Elles repartiront à sa reconnexion sur cette tablette.';

  @override
  String syncErrorsForeignEntry(String name) {
    return 'Écriture de $name — elle devra la reprendre depuis cette liste, sur sa propre session.';
  }

  @override
  String get syncErrorsForeignEntryAnonymous =>
      'Écriture d\'un autre compte — elle devra être reprise depuis sa propre session.';

  @override
  String get syncSheetStatusTitle => 'État de la synchronisation';

  @override
  String get syncSheetStatusSubtitle =>
      'Ce que cette tablette n\'a pas reçu, et les écritures que le serveur a refusées — celles-ci ne repartiront pas d\'elles-mêmes.';

  @override
  String get syncIncompleteReadTitle => 'Certaines données ne descendent pas';

  @override
  String get syncIncompleteReadDescription =>
      'La dernière mise à jour n\'a pas tout ramené. Des écrans peuvent donc paraître vides sans l\'être vraiment. Rien de ce que vous avez saisi n\'est perdu. Si cela dure, votre administrateur peut vérifier les accès de votre compte.';

  @override
  String get syncIncompleteReadRetriableDescription =>
      'La dernière mise à jour s\'est interrompue avant d\'avoir tout ramené. Des écrans peuvent donc paraître vides sans l\'être vraiment. Rien de ce que vous avez saisi n\'est perdu.';

  @override
  String get syncIncompleteReadRetry => 'Réessayer';

  @override
  String get syncErrorsHeldTitle => 'En attente';

  @override
  String get syncErrorsHeldSubtitle =>
      'Ces écritures sont conservées et repartiront dès que leur condition sera levée.';

  @override
  String get editiqueViewerReceiptTitle => 'Reçu de paiement';

  @override
  String get editiqueViewerLoadingTitle => 'Préparation du document…';

  @override
  String get editiqueViewerLoadingMessage =>
      'Le serveur produit la pièce. Cela peut prendre quelques secondes.';

  @override
  String get editiqueViewerPrintLabel => 'Imprimer';

  @override
  String get editiqueViewerShareLabel => 'Partager';

  @override
  String get editiqueViewerCloseLabel => 'Fermer';

  @override
  String get editiqueViewerActionFailed =>
      'L\'action n\'a pas pu aboutir sur cet appareil.';

  @override
  String editiqueViewerDocumentNumberLabel(String number) {
    return 'Pièce n° $number';
  }

  @override
  String get editiqueErrorNetworkTitle => 'Pas de connexion';

  @override
  String get editiqueErrorNetworkMessage =>
      'Le document est produit par le serveur. Reconnectez-vous puis réessayez — rien n\'a été émis.';

  @override
  String get editiqueErrorUncertainTitle => 'Résultat indéterminé';

  @override
  String get editiqueErrorUncertainMessage =>
      'Le serveur n\'a pas répondu à temps. La pièce a peut-être été émise : vérifiez avant d\'en générer une nouvelle.';

  @override
  String get editiqueErrorSessionExpiredTitle => 'Session expirée';

  @override
  String get editiqueErrorSessionExpiredMessage =>
      'Reconnectez-vous pour reprendre l\'émission du document.';

  @override
  String get editiqueErrorForbiddenTitle => 'Accès refusé';

  @override
  String get editiqueErrorForbiddenMessage =>
      'Vous n\'avez pas les droits nécessaires pour éditer cette pièce.';

  @override
  String get editiqueErrorNotFoundTitle => 'Document indisponible';

  @override
  String get editiqueErrorNotFoundMessage =>
      'Le serveur ne trouve pas les éléments nécessaires à cette pièce.';

  @override
  String get editiqueErrorInvalidTitle => 'Émission impossible';

  @override
  String get editiqueErrorInvalidMessage =>
      'Le serveur a refusé la demande. Vérifiez le dossier avant de réessayer.';

  @override
  String get editiqueErrorServerTitle => 'Erreur du serveur';

  @override
  String get editiqueErrorServerMessage =>
      'La pièce n\'a pas pu être produite. Réessayez dans un instant.';

  @override
  String get editiqueErrorRetryLabel => 'Réessayer';

  @override
  String get editiqueErrorReconnectLabel => 'Se reconnecter';

  @override
  String get editiqueViewerStatementTitle => 'Relevé de compte';

  @override
  String get editiqueViewerAttestationTitle => 'Attestation d\'inscription';

  @override
  String get editiqueViewerNotePerceptionTitle => 'Note de perception';

  @override
  String get editiqueViewerClearanceTitle => 'Quitus financier';

  @override
  String editiqueErrorServerDetailLabel(String detail) {
    return 'Motif renvoyé par le serveur : $detail';
  }

  @override
  String get facturationDetailStatementLabel => 'Relevé de compte';

  @override
  String get facturationDetailStatementNoChargesHint =>
      'Aucun frais sur l\'année : le relevé ne peut pas être produit.';

  @override
  String get facturationDetailStatementPendingSyncHint =>
      'Élève pas encore synchronisé : le relevé sera disponible après la prochaine synchronisation.';

  @override
  String get facturationDetailStatementOfflineHint =>
      'Hors connexion : le relevé est produit par le serveur.';

  @override
  String get facturationDetailStatementConfirmTitle =>
      'Générer un relevé de compte ?';

  @override
  String get facturationDetailStatementConfirmMessage =>
      'Le serveur produira une nouvelle pièce numérotée, datée de maintenant. Les relevés déjà remis restent valides — ils ne sont pas remplacés.';

  @override
  String get facturationDetailStatementConfirmAction => 'Générer';

  @override
  String get facturationDetailStatementConfirmCancel => 'Annuler';

  @override
  String get menuDocuments => 'Documents';

  @override
  String get subMenuDocumentsStudent => 'Documents de l\'élève';

  @override
  String get documentsSearchTitle => 'Documents de l\'élève';

  @override
  String get documentsSearchHelpBanner =>
      'Recherchez un élève précis, ou toute une classe, puis ouvrez son catalogue de pièces.';

  @override
  String get documentsSearchCycleLabel => 'Cycle';

  @override
  String get documentsSearchLevelLabel => 'Niveau';

  @override
  String get documentsSearchLevelPlaceholder => 'Choisissez d\'abord un cycle';

  @override
  String get documentsSearchInvitationTitle =>
      'Trouvez l\'élève, ouvrez ses documents';

  @override
  String get documentsSearchInvitationMessage =>
      'Attestation d\'inscription, note de perception, reçu de paiement, relevé de compte et quitus financier : les pièces émissibles pour un élève.';

  @override
  String get documentsEmptyTitle => 'Aucun élève trouvé';

  @override
  String get documentsNoResultsDescription =>
      'Aucun élève inscrit cette année ne correspond à ces critères.';

  @override
  String get documentsOpenCatalogLabel => 'Ouvrir les documents';

  @override
  String get documentsCatalogEyebrow => 'Documents';

  @override
  String get documentsCatalogUnknownStudent => 'Élève';

  @override
  String get documentsGroupScolariteTitle => 'Scolarité';

  @override
  String get documentsGroupScolariteSubtitle => 'Dossier d\'inscription';

  @override
  String get documentsGroupFinancesTitle => 'Finances';

  @override
  String get documentsGroupFinancesSubtitle =>
      'Perception, reçus et attestations de règlement';

  @override
  String get documentsNatureArchivedLabel => 'Figé';

  @override
  String get documentsNatureTimestampedLabel => 'Horodaté';

  @override
  String get documentsHintAttestation =>
      'Pièce archivée : la redemander re-sert exactement le même document, sous le même numéro.';

  @override
  String get documentsHintNotePerception =>
      'Document comptable immuable, émis une seule fois par élève et par année.';

  @override
  String get documentsHintReceipt =>
      'Un reçu par versement. Il s\'émet depuis la Facturation, au moment de l\'encaissement.';

  @override
  String get documentsHintStatement =>
      'Photo du compte à l\'instant de la demande : chaque émission produit une nouvelle pièce numérotée.';

  @override
  String get documentsHintClearance =>
      'Atteste que l\'élève est en règle à la date de la demande. Non archivé, renuméroté à chaque émission.';

  @override
  String get documentsActionEmitLabel => 'Émettre';

  @override
  String get documentsActionConsultLabel => 'Consulter';

  @override
  String get documentsActionGenerateLabel => 'Générer maintenant';

  @override
  String get documentsActionBusyLabel => 'Génération…';

  @override
  String get documentsActionFailedNotice =>
      'La génération a échoué. Le document n\'a pas été produit.';

  @override
  String get documentsBlockedPendingSyncNotice =>
      'Élève pas encore synchronisé : la pièce sera disponible après la prochaine synchronisation.';

  @override
  String get documentsBlockedEnrollmentPendingSyncNotice =>
      'Dossier pas encore synchronisé : l\'attestation sera disponible après la prochaine synchronisation.';

  @override
  String get documentsBlockedMissingEnrollmentNotice =>
      'Dossier introuvable depuis ce lien : rouvrez la fiche depuis la liste des élèves.';

  @override
  String get documentsBlockedOfflineNotice =>
      'Hors connexion : cette pièce est produite par le serveur.';

  @override
  String documentsConfirmGenerateTitle(String document) {
    return 'Générer : $document ?';
  }

  @override
  String get documentsConfirmGenerateMessage =>
      'Le serveur produira une nouvelle pièce numérotée, datée de maintenant. Les pièces déjà remises restent valides — elles ne sont pas remplacées.';

  @override
  String get documentsConfirmClearanceWarning =>
      'Le quitus est émis quel que soit le solde : un élève qui n\'est pas en règle recevra une pièce portant la mention « NON EN RÈGLE ».';

  @override
  String get documentsConfirmGenerateAction => 'Générer';

  @override
  String get documentsConfirmGenerateCancel => 'Annuler';

  @override
  String documentsLastIssueSubtitle(String date, String reference) {
    return 'Dernière émission $date · réf. $reference';
  }

  @override
  String documentsCancelledNotice(String date) {
    return 'Pièce annulée le $date par l\'établissement.';
  }

  @override
  String documentsCancelledWithReasonNotice(String date, String reason) {
    return 'Pièce annulée le $date par l\'établissement — $reason';
  }

  @override
  String facturationReceiptCancelledNotice(String date) {
    return 'Reçu annulé le $date par l\'établissement.';
  }

  @override
  String facturationReceiptCancelledWithReasonNotice(
    String date,
    String reason,
  ) {
    return 'Reçu annulé le $date par l\'établissement — $reason';
  }

  @override
  String get ticketDocumentTitle => 'Ticket de perception';

  @override
  String get ticketProvisionalBanner => 'Provisoire';

  @override
  String get ticketReferenceLabel => 'Réf.';

  @override
  String get ticketCashierLabel => 'Caissier :';

  @override
  String get ticketStudentLabel => 'Élève :';

  @override
  String get ticketMatriculationLabel => 'Matricule :';

  @override
  String get ticketClassroomLabel => 'Classe :';

  @override
  String get ticketAmountReceivedLabel => 'Montant reçu';

  @override
  String get ticketAllocationsLabel => 'Répartition';

  @override
  String get ticketAdvanceLabel => 'Avance (non imputée)';

  @override
  String get ticketBalanceLabel => 'Solde';

  @override
  String get ticketBalanceReservation => 'sous réserve de synchronisation';

  @override
  String get ticketKeepNotice =>
      'Conservez ce ticket jusqu\'à la remise de votre reçu définitif.';

  @override
  String get ticketPrintLabel => 'Imprimer le ticket de perception';

  @override
  String get ticketPrintFailed =>
      'Impression indisponible : le ticket n\'a pas pu être produit.';

  @override
  String get ticketRefusedUnknownStudent =>
      'Impression refusée : le nom de l\'élève n\'est pas connu de cette tablette. Le versement est bien enregistré — réimprimez après la prochaine synchronisation.';

  @override
  String get ticketCutNotice => 'Découpez le long du cadre.';

  @override
  String get ticketPrinterPickerTitle => 'Choisir l\'imprimante';

  @override
  String get ticketPrinterUnnamed => 'Imprimante sans nom';

  @override
  String get ticketPrinterProblemPermission =>
      'Permission « Appareils à proximité » refusée — impression PDF à la place.';

  @override
  String get ticketPrinterProblemBluetoothOff =>
      'Bluetooth éteint — impression PDF à la place.';

  @override
  String get ticketPrinterProblemNoPrinter =>
      'Aucune imprimante appairée — impression PDF à la place.';

  @override
  String get ticketPrinterProblemUnreachable =>
      'Imprimante injoignable, éteinte ou hors de portée — impression PDF à la place.';

  @override
  String get paymentAnomalyBannerTitle => 'Trop-perçu à arbitrer';

  @override
  String get paymentAnomalyBannerFallback =>
      'Un encaissement dépasse le reste dû.';

  @override
  String get paymentAnomalyAcknowledgeLabel => 'Traité';

  @override
  String paymentAnomalyOthersPending(int count) {
    return '$count autre(s) en attente';
  }

  @override
  String get documentsBlockedEnrollmentUnreadableNotice =>
      'Dossier illisible sur cette tablette : l\'attestation n\'est pas disponible ici.';
}
